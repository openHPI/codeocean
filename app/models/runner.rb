# frozen_string_literal: true

require 'forwardable'

class Runner < ApplicationRecord
  belongs_to :execution_environment
  belongs_to :user, polymorphic: true

  before_validation :request_id

  validates :execution_environment, :user, :runner_id, presence: true

  STRATEGY_NAME = CodeOcean::Config.new(:code_ocean).read[:runner_management][:strategy]
  UNUSED_EXPIRATION_TIME = CodeOcean::Config.new(:code_ocean).read[:runner_management][:unused_runner_expiration_time].seconds
  BASE_URL = CodeOcean::Config.new(:code_ocean).read[:runner_management][:url]
  DELEGATED_STRATEGY_METHODS = %i[destroy_at_management attach_to_execution copy_files].freeze

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

  DELEGATED_STRATEGY_METHODS.each do |method|
    define_method(method) do |*args, &block|
      @strategy.send(method, *args, &block)
    rescue Runner::Error::NotFound
      request_new_id
      save
      @strategy.send(method, *args, &block)
    end
  end

  private

  def request_id
    request_new_id if runner_id.blank?
  end

  def request_new_id
    strategy_class = self.class.strategy_class
    self.runner_id = strategy_class.request_from_management(execution_environment)
    @strategy = strategy_class.new(runner_id, execution_environment)
  rescue Runner::Error::NotFound
    if strategy_class.sync_environment(execution_environment)
      raise Runner::Error::NotFound.new(
        "The execution environment with id #{execution_environment.id} was not found and was successfully synced with the runner management"
      )
    else
      raise Runner::Error::NotFound.new(
        "The execution environment with id #{execution_environment.id} was not found and could not be synced with the runner management"
      )
    end
  end
end
