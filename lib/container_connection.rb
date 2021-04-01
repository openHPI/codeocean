require 'faye/websocket/client'

class ContainerConnection
  EVENTS = %i[start output exit stdout stderr].freeze

  def initialize(url)
    @socket = Faye::WebSocket::Client.new(url, [], ping: 5)

    %i[open message error close].each do |event_type|
      @socket.on event_type do |event| __send__(:"on_#{event_type}", event) end
    end

    EVENTS.each { |event_type| instance_variable_set(:"@#{event_type}_callback", lambda {|e|}) }
    @start_callback = lambda {}
    @exit_code = 0
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
    event = decode(event.data)
    case event[:type].to_sym
    when :exit_code
      @exit_code = event[:data]
    when :stderr
      @stderr_callback.call event[:data]
      @output_callback.call event[:data]
    when :stdout
      @stdout_callback.call event[:data]
      @output_callback.call event[:data]
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