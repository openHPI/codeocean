# frozen_string_literal: true

class Runner
  class Error < ApplicationError
    attr_accessor :waiting_duration, :execution_duration, :starting_time

    class BadRequest < Error; end

    class EnvironmentNotFound < Error; end

    class ExecutionTimeout < Error; end

    class InternalServerError < Error; end

    class NotAvailable < Error; end

    class Unauthorized < Error; end

    class RunnerNotFound < Error; end

    class FaradayError < Error; end

    class UnexpectedResponse < Error; end

    class WorkspaceError < Error; end

    class Unknown < Error; end
  end
end
