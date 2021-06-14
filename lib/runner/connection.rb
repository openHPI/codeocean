# frozen_string_literal: true

require 'faye/websocket/client'
require 'json_schemer'

class Runner::Connection
  # These are events for which callbacks can be registered.
  EVENTS = %i[start output exit stdout stderr].freeze
  BACKEND_OUTPUT_SCHEMA = JSONSchemer.schema(JSON.parse(File.read('lib/runner/backend-output.schema.json')))
  TIMEOUT_EXIT_STATUS = -100

  def initialize(url)
    @socket = Faye::WebSocket::Client.new(url, [], ping: 5)

    # For every event type of faye websockets, the corresponding
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

  def send(data)
    @socket.send(encode(data))
  end

  private

  def decode(event)
    JSON.parse(event).deep_symbolize_keys
  end

  def encode(data)
    data
  end

  def on_message(event)
    return unless BACKEND_OUTPUT_SCHEMA.valid?(JSON.parse(event.data))

    event = decode(event.data)
    # There is one `handle_` method for every message type defined in the WebSocket schema.
    __send__("handle_#{event[:type]}", event)
  end

  def on_open(_event)
    @start_callback.call
  end

  def on_error(_event); end

  def on_close(_event)
    @exit_callback.call @exit_code
  end

  def handle_exit(event)
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
    @exit_code = TIMEOUT_EXIT_STATUS
    raise Runner::Error::ExecutionTimeout.new('Execution exceeded its time limit')
  end
end
