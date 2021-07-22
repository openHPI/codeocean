# frozen_string_literal: true

require 'faye/websocket/client'
require 'json_schemer'

class Runner::Connection
  # These are events for which callbacks can be registered.
  EVENTS = %i[start output exit stdout stderr].freeze
  WEBSOCKET_MESSAGE_TYPES = %i[start stdout stderr error timeout exit].freeze
  BACKEND_OUTPUT_SCHEMA = JSONSchemer.schema(JSON.parse(File.read('lib/runner/backend-output.schema.json')))

  attr_writer :status
  attr_reader :error

  def initialize(url, strategy, event_loop)
    @socket = Faye::WebSocket::Client.new(url, [], ping: 5)
    @strategy = strategy
    @status = :established
    @event_loop = event_loop

    # For every event type of Faye WebSockets, the corresponding
    # RunnerConnection method starting with `on_` is called.
    %i[open message error close].each do |event_type|
      @socket.on(event_type) {|event| __send__(:"on_#{event_type}", event) }
    end

    # This registers empty default callbacks.
    EVENTS.each {|event_type| instance_variable_set(:"@#{event_type}_callback", ->(e) {}) }
    @start_callback = -> {}
    # Fail if no exit status was returned.
    @exit_code = 1
  end

  def on(event, &block)
    return unless EVENTS.include? event

    instance_variable_set(:"@#{event}_callback", block)
  end

  def send(raw_data)
    encoded_message = encode(raw_data)
    Rails.logger.debug { "#{Time.zone.now.getutc}: Sending to #{@socket.url}: #{encoded_message.inspect}" }
    @socket.send(encoded_message)
  end

  def close(status)
    return unless active?

    @status = status
    @socket.close
  end

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

  def on_message(raw_event)
    Rails.logger.debug { "#{Time.zone.now.getutc}: Receiving from #{@socket.url}: #{raw_event.data.inspect}" }
    event = decode(raw_event)
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

  def on_open(_event)
    @start_callback.call
  end

  def on_error(_event); end

  def on_close(_event)
    Rails.logger.debug { "#{Time.zone.now.getutc}: Closing connection to #{@socket.url} with status: #{@status}" }
    case @status
      when :timeout
        @error = Runner::Error::ExecutionTimeout.new('Execution exceeded its time limit')
      when :terminated_by_codeocean, :terminated_by_management
        @exit_callback.call @exit_code
      when :terminated_by_client, :error
      else # :established
        # If the runner is killed by the DockerContainerPool after the maximum allowed time per user and
        # while the owning user is running an execution, the command execution stops and log output is incomplete.
        @error = Runner::Error::Unknown.new('Execution terminated with an unknown reason')
    end
    @event_loop.stop
  end

  def handle_exit(event)
    @status = :terminated_by_management
    @exit_code = event[:data]
  end

  def handle_stdout(event)
    @stdout_callback.call event[:data]
    @output_callback.call event[:data]
  end

  def handle_stderr(event)
    @stderr_callback.call event[:data]
    @output_callback.call event[:data]
  end

  def handle_error(_event); end

  def handle_start(_event); end

  def handle_timeout(_event)
    @status = :timeout
  end
end
