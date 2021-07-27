# frozen_string_literal: true

class Runner < ApplicationRecord
  belongs_to :execution_environment
  belongs_to :user, polymorphic: true

  before_validation :request_id

  validates :execution_environment, :user, :runner_id, presence: true

  STRATEGY_NAME = CodeOcean::Config.new(:code_ocean).read[:runner_management][:strategy]
  UNUSED_EXPIRATION_TIME = CodeOcean::Config.new(:code_ocean).read[:runner_management][:unused_runner_expiration_time].seconds
  BASE_URL = CodeOcean::Config.new(:code_ocean).read[:runner_management][:url]

  attr_accessor :strategy

  def self.strategy_class
    "runner/strategy/#{STRATEGY_NAME}".camelize.constantize
  end

  def self.for(user, exercise)
    execution_environment = ExecutionEnvironment.find(exercise.execution_environment_id)

    runner = find_by(user: user, execution_environment: execution_environment)
    if runner.nil?
      runner = Runner.create(user: user, execution_environment: execution_environment)
      raise Runner::Error::Unknown.new("Runner could not be saved: #{runner.errors.inspect}") unless runner.persisted?
    else
      runner.strategy = strategy_class.new(runner.runner_id, runner.execution_environment)
    end

    runner
  end

  def copy_files(files)
    @strategy.copy_files(files)
  rescue Runner::Error::RunnerNotFound
    request_new_id
    save
    @strategy.copy_files(files)
  end

  def attach_to_execution(command, &block)
    starting_time = Time.zone.now
    begin
      # As the EventMachine reactor is probably shared with other threads, we cannot use EventMachine.run with
      # stop_event_loop to wait for the WebSocket connection to terminate. Instead we use a self built event
      # loop for that: Runner::EventLoop. The attach_to_execution method of the strategy is responsible for
      # initializing its Runner::Connection with the given event loop. The Runner::Connection class ensures that
      # this event loop is stopped after the socket was closed.
      event_loop = Runner::EventLoop.new
      socket = @strategy.attach_to_execution(command, event_loop, &block)
      event_loop.wait
      raise socket.error if socket.error.present?
    rescue Runner::Error => e
      e.execution_duration = Time.zone.now - starting_time
      raise
    end
    Time.zone.now - starting_time # execution duration
  end

  def destroy_at_management
    @strategy.destroy_at_management
  end

  private

  def request_id
    request_new_id if runner_id.blank?
  end

  def request_new_id
    strategy_class = self.class.strategy_class
    begin
      self.runner_id = strategy_class.request_from_management(execution_environment)
      @strategy = strategy_class.new(runner_id, execution_environment)
    rescue Runner::Error::EnvironmentNotFound
      if strategy_class.sync_environment(execution_environment)
        raise Runner::Error::EnvironmentNotFound.new(
          "The execution environment with id #{execution_environment.id} was not found and was successfully synced with the runner management"
        )
      else
        raise Runner::Error::EnvironmentNotFound.new(
          "The execution environment with id #{execution_environment.id} was not found and could not be synced with the runner management"
        )
      end
    end
  end
end
