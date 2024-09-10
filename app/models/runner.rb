# frozen_string_literal: true

class Runner < ApplicationRecord
  include ContributorCreation
  belongs_to :execution_environment

  before_validation :request_id
  validates :runner_id, presence: true

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
    return @management_active if defined? @management_active

    runner_management = CodeOcean::Config.new(:code_ocean).read[:runner_management]
    if runner_management
      @management_active = runner_management[:enabled]
    else
      @management_active = false
    end
  end

  def self.for(contributor, execution_environment)
    runner = find_by(contributor:, execution_environment:)
    if runner.nil?
      runner = Runner.create(contributor:, execution_environment:)
      # The `strategy` is added through the before_validation hook `:request_id`.
      raise Runner::Error::Unknown.new("Runner could not be saved: #{runner.errors.inspect}") unless runner.persisted?
    else
      # This information is required but not persisted in the runner model.
      runner.strategy = strategy_class.new(runner.runner_id, runner.execution_environment)
    end

    runner
  end

  def copy_files(files)
    reserve!
    @strategy.copy_files(files)
  rescue Runner::Error => e
    Sentry.capture_exception(e) unless e.is_a? Runner::Error::RunnerNotFound
    request_new_id
    save
    @strategy.copy_files(files)
  ensure
    release!
  end

  def download_file(desired_file, privileged_execution:, exclusive: true, &)
    reserve! if exclusive
    @strategy.download_file(desired_file, privileged_execution:, &)
  ensure
    release! if exclusive
  end

  def retrieve_files(raise_exception: true, exclusive: true, **)
    reserve! if exclusive
    try = 0
    begin
      if try.nonzero?
        request_new_id
        save
      end
      @strategy.retrieve_files(**)
    rescue Runner::Error::RunnerNotFound => e
      Rails.logger.debug { "Retrieving files failed for the first time: #{e.message}" }
      try += 1

      if try == 1
        # This is only used if no files were copied to the runner. Thus requesting a second runner is performed here
        # Reset the variable. This is required to prevent raising an outdated exception after a successful second try
        e = nil
        retry
      end
    ensure
      # We forward the exception if requested
      raise e if raise_exception && defined?(e) && e.present?

      # Otherwise, we return an hash with empty files and release the runner
      release! if exclusive
    end
  end

  def attach_to_execution(command, privileged_execution: false, exclusive: true, &)
    reserve! if exclusive
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Starting execution with Runner #{id} for #{contributor_type} #{contributor_id}." }
    starting_time = Time.zone.now
    begin
      # As the EventMachine reactor is probably shared with other threads, we cannot use EventMachine.run with
      # stop_event_loop to wait for the WebSocket connection to terminate. Instead we use a self built event
      # loop for that: Runner::EventLoop. The attach_to_execution method of the strategy is responsible for
      # initializing its Runner::Connection with the given event loop. The Runner::Connection class ensures that
      # this event loop is stopped after the socket was closed.
      event_loop = Runner::EventLoop.new
      socket = @strategy.attach_to_execution(command, event_loop, starting_time, privileged_execution:, &)
      event_loop.wait
      raise socket.error if socket.error.present?
    rescue Runner::Error => e
      e.starting_time = starting_time
      e.execution_duration = Time.zone.now - starting_time
      raise
    end
    Rails.logger.debug { "#{Time.zone.now.getutc.inspect}: Stopped execution with Runner #{id} for #{contributor_type} #{contributor_id}." }
    Time.zone.now - starting_time # execution duration
  ensure
    release! if exclusive
  end

  def execute_command(command, privileged_execution: false, raise_exception: true, exclusive: true)
    output = {
      stdout: +'',
      stderr: +'',
      messages: [],
      exit_code: 1, # default to error
    }
    try = 0

    begin
      if try.nonzero?
        request_new_id
        save
      end

      execution_time = attach_to_execution(command, privileged_execution:, exclusive:) do |socket, starting_time|
        socket.on :stderr do |data|
          output[:stderr] << data
          output[:messages].push({cmd: :write, stream: :stderr, log: data, timestamp: Time.zone.now - starting_time})
        end
        socket.on :stdout do |data|
          output[:stdout] << data
          output[:messages].push({cmd: :write, stream: :stdout, log: data, timestamp: Time.zone.now - starting_time})
        end
        socket.on :exit do |received_exit_code|
          output[:exit_code] = received_exit_code
        end
      end
      output.merge!(container_execution_time: execution_time, status: output[:exit_code].zero? ? :ok : :failed)
    rescue Runner::Error::ExecutionTimeout => e
      Rails.logger.debug { "Running command `#{command}` timed out: #{e.message}" }
      output.merge!(status: :timeout, container_execution_time: e.execution_duration)
    rescue Runner::Error::OutOfMemory => e
      Rails.logger.debug { "Running command `#{command}` caused an out of memory error: #{e.message}" }
      output.merge!(status: :out_of_memory, container_execution_time: e.execution_duration)
    rescue Runner::Error::RunnerInUse => e
      Rails.logger.debug { "Running command `#{command}` failed because the runner was already in use: #{e.message}" }
      output.merge!(status: :runner_in_use, container_execution_time: e.execution_duration)
    rescue Runner::Error::RunnerNotFound => e
      Rails.logger.debug { "Running command `#{command}` failed for the first time: #{e.message}" }
      try += 1

      if try == 1
        # This is only used if no files were copied to the runner. Thus requesting a second runner is performed here
        # Reset the variable. This is required to prevent raising an outdated exception after a successful second try
        e = nil
        retry
      end

      Rails.logger.debug { "Running command `#{command}` failed for the second time: #{e.message}" }
      output.merge!(status: :failed, container_execution_time: e.execution_duration)
    rescue Runner::Error => e
      Rails.logger.debug { "Running command `#{command}` failed: #{e.message}" }
      output.merge!(status: :container_depleted, container_execution_time: e.execution_duration)
    ensure
      # We forward the exception if requested
      raise e if raise_exception && defined?(e) && e.present?

      # If the process was killed with SIGKILL, it is most likely that the OOM killer was triggered.
      output[:status] = :out_of_memory if output[:exit_code] == 137
    end
  end

  def destroy_at_management
    @strategy.destroy_at_management
    update!(runner_id: nil, reserved_until: nil)
  end

  def reserve!
    with_lock do
      if reserved_until.present? && reserved_until > Time.zone.now
        @error = Runner::Error::RunnerInUse.new("The desired Runner #{id} is already in use until #{reserved_until.iso8601}.")
        raise @error
      else
        update!(reserved_until: Time.zone.now + execution_environment.permitted_execution_time.seconds)
        @error = nil
      end
    end
  end

  def release!
    return if @error.present?

    with_lock do
      update!(reserved_until: nil)
    end
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
      begin
        strategy_class.sync_environment(execution_environment)
      rescue Runner::Error
        # An additional error was raised during synchronization
        raise Runner::Error::EnvironmentNotFound.new(
          "The execution environment with id #{execution_environment.id} was not found by the runner management. " \
          'In addition, it could not be synced so that this probably indicates a permanent error.'
        )
      else
        # No error was raised during synchronization
        raise Runner::Error::EnvironmentNotFound.new(
          "The execution environment with id #{execution_environment.id} was not found yet by the runner management. " \
          'It has been successfully synced now so that the next request should be successful.'
        )
      end
    end
  end
end
