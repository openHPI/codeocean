require 'faye/websocket/client'

class ContainerConnection
  EVENTS = %i[start message exit stdout stderr].freeze

  def initialize(url)
    @socket = Faye::WebSocket::Client.new(url, [], ping: 0.1)

    %i[open message error close].each do |event_type|
      @socket.on event_type, &:"on_#{event_type}"
    end

    EVENTS.each { |event_type| instance_variable_set(:"@#{event_type}_callback", lambda {}) }
  end

  def on(event, &block)
    return unless EVENTS.include? event

    instance_variable_set(:"@#{event}_callback", block)
  end

  def send(data)
    @socket.send(data)
  end

  private

  def parse(event)
    JSON.parse(event.data).deep_symbolize_keys
  end

  def on_message(event)
    event = parse(event)
    case event[:type]
    when :exit_code
      @exit_code = event[:data]
    when :stderr
      @stderr_callback.call event[:data]
      @message_callback.call event[:data]
    when :stdout
      @stdout_callback.call event[:data]
      @message_callback.call event[:data]
    else
      :error
    end
  end

  def on_open(event)
    @start_callback.call
  end

  def on_error(event)
  end

  def on_close(event)
    @exit_callback.call @exit_code
  end
end