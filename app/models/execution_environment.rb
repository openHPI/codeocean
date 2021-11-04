# frozen_string_literal: true

require File.expand_path('../../lib/active_model/validations/boolean_presence_validator', __dir__)

class ExecutionEnvironment < ApplicationRecord
  include Creation
  include DefaultValues

  VALIDATION_COMMAND = 'whoami'
  DEFAULT_CPU_LIMIT = 20
  DEFAULT_MEMORY_LIMIT = 256
  MINIMUM_MEMORY_LIMIT = 4

  after_initialize :set_default_values

  has_many :exercises
  belongs_to :file_type
  has_many :error_templates

  scope :with_exercises, -> { where('id IN (SELECT execution_environment_id FROM exercises)') }

  validate :valid_test_setup?
  validate :working_docker_image?, if: :validate_docker_image?
  validates :docker_image, presence: true
  validates :memory_limit,
    numericality: {greater_than_or_equal_to: MINIMUM_MEMORY_LIMIT, only_integer: true}, presence: true
  validates :network_enabled, boolean_presence: true
  validates :name, presence: true
  validates :permitted_execution_time, numericality: {only_integer: true}, presence: true
  validates :pool_size, numericality: {only_integer: true}, presence: true
  validates :run_command, presence: true
  validates :cpu_limit, presence: true, numericality: {greater_than: 0, only_integer: true}
  before_validation :clean_exposed_ports
  validates :exposed_ports, array: {numericality: {greater_than_or_equal_to: 0, less_than: 65_536, only_integer: true}}

  after_destroy :delete_runner_environment
  after_save :working_docker_image?, if: :validate_docker_image?

  after_rollback :delete_runner_environment, on: :create
  after_rollback :sync_runner_environment, on: %i[update destroy]

  def to_s
    name
  end

  def to_json(*_args)
    {
      id: id,
      image: docker_image,
      prewarmingPoolSize: pool_size,
      cpuLimit: cpu_limit,
      memoryLimit: memory_limit,
      networkAccess: network_enabled,
      exposedPorts: exposed_ports,
    }.to_json
  end

  def exposed_ports_list
    exposed_ports.join(', ')
  end

  def clean_exposed_ports
    self.exposed_ports = exposed_ports.uniq.sort
  end
  private :clean_exposed_ports

  def valid_test_setup?
    if test_command? ^ testing_framework?
      errors.add(:test_command,
        I18n.t('activerecord.errors.messages.together',
          attribute: I18n.t('activerecord.attributes.execution_environment.testing_framework')))
    end
  end
  private :valid_test_setup?

  def validate_docker_image?
    docker_image.present? && !Rails.env.test?
  end
  private :validate_docker_image?

  def working_docker_image?
    runner = Runner.for(author, self)
    output = runner.execute_command(VALIDATION_COMMAND)
    errors.add(:docker_image, "error: #{output[:stderr]}") if output[:stderr].present?
  rescue Runner::Error::NotAvailable => e
    Rails.logger.info("The Docker image could not be verified: #{e}")
  rescue Runner::Error => e
    errors.add(:docker_image, "error: #{e}")
  end

  def delete_runner_environment
    Runner.strategy_class.remove_environment(self)
  rescue Runner::Error => e
    unless errors.include?(:docker_image)
      errors.add(:docker_image, "error: #{e}")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def sync_runner_environment
    previous_saved_environment = self.class.find(id)
    Runner.strategy_class.sync_environment(previous_saved_environment)
  rescue Runner::Error => e
    unless errors.include?(:docker_image)
      errors.add(:docker_image, "error: #{e}")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end
end
