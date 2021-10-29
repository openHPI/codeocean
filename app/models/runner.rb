# frozen_string_literal: true

class Runner < ApplicationRecord
  belongs_to :execution_environment
  belongs_to :user, polymorphic: true

  before_validation :request_id

  validates :execution_environment, :user, :runner_id, presence: true

  attr_accessor :strategy

  def self.strategy_class
    @strategy_class ||= if Runner.management_active?
                          strategy_name = CodeOcean::Config.new(:code_ocean).read[:runner_management][:strategy]
                          "runner/strategy/#{strategy_name}".camelize.constantize
                        else
                          Runner::Strategy::Null
                        end
  end

  def self.management_active?
    @management_active ||= CodeOcean::Config.new(:code_ocean).read[:runner_management][:enabled]
  end

  def self.for(user, execution_environment)
    runner = find_by(user: user, execution_environment: execution_environment)
    if runner.nil?
      runner = Runner.create(user: user, execution_environment: execution_environment)
      # The `strategy` is added through the before_validation hook `:request_id`.
      raise Runner::Error::Unknown.new("Runner could not be saved: #{runner.errors.inspect}") unless runner.persisted?
    else
      # This information is required but not persisted in the runner model.
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

  def execute_command(command, raise_exception: false)
    output = {}
    stdout = +''
    stderr = +''
    try = 0
    begin
      exit_code = 1 # default to error
      execution_time = attach_to_execution(command) do |socket|
        socket.on :stderr do |data|
          stderr << data
        end
        socket.on :stdout do |data|
          stdout << data
        end
        socket.on :exit do |received_exit_code|
          exit_code = received_exit_code
        end
      end
      output.merge!(container_execution_time: execution_time, status: exit_code.zero? ? :ok : :failed)
    rescue Runner::Error::ExecutionTimeout => e
      Rails.logger.debug { "Running command `#{command}` timed out: #{e.message}" }
      output.merge!(status: :timeout, container_execution_time: e.execution_duration)
    rescue Runner::Error::RunnerNotFound => e
      Rails.logger.debug { "Running command `#{command}` failed for the first time: #{e.message}" }
      try += 1
      request_new_id
      save
      retry if try == 1

      Rails.logger.debug { "Running command `#{command}` failed for the second time: #{e.message}" }
      output.merge!(status: :failed, container_execution_time: e.execution_duration)
    rescue Runner::Error => e
      Rails.logger.debug { "Running command `#{command}` failed: #{e.message}" }
      output.merge!(status: :failed, container_execution_time: e.execution_duration)
    ensure
      # We forward the exception if requested
      raise e if raise_exception && defined?(e) && e.present?

      output.merge!(stdout: stdout, stderr: stderr)
    end
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
      # Whenever the environment could not be found by the runner management, we
      # try to synchronize it and then forward a more specific error to our callee.
      if strategy_class.sync_environment(execution_environment)
        raise Runner::Error::EnvironmentNotFound.new(
          "The execution environment with id #{execution_environment.id} was not found yet by the runner management. "\
          'It has been successfully synced now so that the next request should be successful.'
        )
      else
        raise Runner::Error::EnvironmentNotFound.new(
          "The execution environment with id #{execution_environment.id} was not found by the runner management."\
          'In addition, it could not be synced so that this probably indicates a permanent error.'
        )
      end
    end
  end
end
