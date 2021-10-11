# frozen_string_literal: true

require 'faye/websocket/client'
require 'json_schemer'

class Runner::Connection
  # These are events for which callbacks can be registered.
  EVENTS = %i[start exit stdout stderr].freeze
  WEBSOCKET_MESSAGE_TYPES = %i[start stdout stderr error timeout exit].freeze
  BACKEND_OUTPUT_SCHEMA = JSONSchemer.schema(JSON.parse(File.read('lib/runner/backend-output.schema.json')))

  attr_writer :status
  attr_reader :error

  def initialize(url, strategy, event_loop, locale = I18n.locale)
    # The `ping` value is measured in seconds and specifies how often a Ping frame should be sent.
    # Internally, Faye::WebSocket uses EventMachine and the `ping` value is used to wake the EventMachine thread
    # The `tls` option is used to customize the validation of TLS connections.
    # Passing `nil` as a `root_cert_file` is okay and done so for the DockerContainerPool.
    @socket = Faye::WebSocket::Client.new(url, [], ping: 0.1, tls: {root_cert_file: Runner.strategy_class.config[:ca_file]})
    @strategy = strategy
    @status = :established
    @event_loop = event_loop
    @locale = locale
    @buffer = Buffer.new

    # For every event type of Faye WebSockets, the corresponding
    # RunnerConnection method starting with `on_` is called.
    %i[open message error close].each do |event_type|
      @socket.on(event_type) do |event|
        # The initial locale when establishing the connection is used for all callbacks
        I18n.with_locale(@locale) { __send__(:"on_#{event_type}", event) }
      end
    end

    # This registers empty default callbacks.
    EVENTS.each {|event_type| instance_variable_set(:"@#{event_type}_callback", ->(e) {}) }
    @start_callback = -> {}
    # Fail if no exit status was returned.
    @exit_code = 1
  end

  # Register a callback based on the WebSocket connection state
  def on(event, &block)
    return unless EVENTS.include? event

    instance_variable_set(:"@#{event}_callback", block)
  end

  # Send arbitrary data in the WebSocket connection
  def send_data(raw_data)
    encoded_message = encode(raw_data)
    Rails.logger.debug { "#{Time.zone.now.getutc}: Sending to #{@socket.url}: #{encoded_message.inspect}" }
    @socket.send(encoded_message)
  end

  # Close the WebSocket connection
  def close(status)
    return unless active?

    @status = status
    @socket.close
  end

  # Check if the WebSocket connection is currently established
  def active?
    @status == :established
  end

  private

  def decode(_raw_event)
    raise NotImplementedError
  end

  def encode(_data)
    raise NotImplementedError
  end

  # === WebSocket Callbacks
  # These callbacks are executed based on events indicated by Faye WebSockets and are
  # independent of the JSON specification that is used within the WebSocket once established.

  def on_message(raw_event)
    Rails.logger.debug { "#{Time.zone.now.getutc}: Receiving from #{@socket.url}: #{raw_event.data.inspect}" }
    @buffer.store raw_event.data
    @buffer.events.each do |event_data|
      forward_message event_data
    end
  end

  def forward_message(event_data)
    event = decode(event_data)
    return unless BACKEND_OUTPUT_SCHEMA.valid?(event)

    event = event.deep_symbolize_keys
    message_type = event[:type].to_sym
    if WEBSOCKET_MESSAGE_TYPES.include?(message_type)
      __send__("handle_#{message_type}", event)
    else
      @error = Runner::Error::UnexpectedResponse.new("Unknown WebSocket message type: #{message_type}")
      close(:error)
    end
  end
  private :forward_message

  def on_open(_event)
    @start_callback.call
  end

  def on_error(_event); end

  def on_close(_event)
    Rails.logger.debug { "#{Time.zone.now.getutc}: Closing connection to #{@socket.url} with status: #{@status}" }
    forward_message @buffer.flush

    # Depending on the status, we might want to destroy the runner at management.
    # This ensures we get a new runner on the next request.
    # All failing runs, those cancelled by the user or those hitting a timeout or error are subject to this mechanism.

    case @status
      when :timeout
        @strategy.destroy_at_management
        @error = Runner::Error::ExecutionTimeout.new('Execution exceeded its time limit')
      when :terminated_by_codeocean, :terminated_by_management
        @exit_callback.call @exit_code
      when :terminated_by_client, :error
        @strategy.destroy_at_management
      else # :established
        # If the runner is killed by the DockerContainerPool after the maximum allowed time per user and
        # while the owning user is running an execution, the command execution stops and log output is incomplete.
        @strategy.destroy_at_management
        @error = Runner::Error::Unknown.new('Execution terminated with an unknown reason')
    end
    @event_loop.stop
  end

  # === Message Handlers
  # Each message type indicated by the +type+ attribute in the JSON
  # sent be the runner management has a dedicated method.
  # Context:: All registered handlers are executed in the scope of
  #           the bindings they had where they were registered.
  #           Information not stored in the binding, such as the
  #           locale or call stack are not available during execution!

  def handle_exit(event)
    @status = :terminated_by_management
    @exit_code = event[:data]
  end

  def handle_stdout(event)
    @stdout_callback.call event[:data]
  end

  def handle_stderr(event)
    @stderr_callback.call event[:data]
  end

  def handle_error(_event); end

  def handle_start(_event); end

  def handle_timeout(_event)
    @status = :timeout
  end
end
