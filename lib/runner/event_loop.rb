# frozen_string_literal: true

# EventLoop is an abstraction around Ruby's queue so that its usage is better
# understandable in our context.
class Runner::EventLoop
  def initialize
    @queue = Queue.new
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
end
