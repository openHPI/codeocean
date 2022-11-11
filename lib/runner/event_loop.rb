# frozen_string_literal: true

# EventLoop is an abstraction around Ruby's queue so that its usage is better
# understandable in our context.
class Runner::EventLoop
  def initialize
    @queue = Queue.new
    ensure_event_machine
  end

  # wait waits until another thread calls stop on this EventLoop.
  # There may only be one active wait call per loop at a time, otherwise it is not
  # deterministic which one will be unblocked if stop is called.
  def wait
    @queue.pop
  end

  # stop unblocks the currently active wait call. If there is none, the
  # next call to wait will not be blocking.
  def stop
    @queue.push nil if @queue.empty?
  end

  private

  # If there are multiple threads trying to connect to the WebSocket of their execution at the same time,
  # the Faye WebSocket connections will use the same reactor. We therefore only need to start an EventMachine
  # if there isn't a running reactor yet.
  # See this StackOverflow answer: https://stackoverflow.com/a/8247947
  def ensure_event_machine
    unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
      queue = Queue.new
      Thread.new do
        EventMachine.run { queue.push nil }
      rescue StandardError => e
        Sentry.capture_exception(e)
      ensure
        ActiveRecord::Base.connection_pool.release_connection
      end
      queue.pop
    end
  end
end
