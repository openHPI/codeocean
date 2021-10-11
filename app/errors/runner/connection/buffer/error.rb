# frozen_string_literal: true

class Runner::Connection::Buffer
  class Error < ApplicationError
    class NotEmpty < Error; end
  end
end
