# frozen_string_literal: true

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
  has_many :testrun_execution_environments, dependent: :destroy

  scope :with_exercises, -> { where('id IN (SELECT execution_environment_id FROM exercises)') }

  before_validation :clean_exposed_ports

  validate :valid_test_setup?
  validates :docker_image, presence: true
  validates :memory_limit,
    numericality: {greater_than_or_equal_to: MINIMUM_MEMORY_LIMIT, only_integer: true}, presence: true
  validates :network_enabled, inclusion: [true, false]
  validates :privileged_execution, inclusion: [true, false]
  validates :name, presence: true
  validates :permitted_execution_time, numericality: {only_integer: true}, presence: true
  validates :pool_size, numericality: {only_integer: true}, presence: true
  validates :run_command, presence: true
  validates :cpu_limit, presence: true, numericality: {greater_than: 0, only_integer: true}
  validates :exposed_ports, array: {numericality: {greater_than_or_equal_to: 0, less_than: 65_536, only_integer: true}}

  after_destroy :delete_runner_environment
  after_save :working_docker_image?, if: :validate_docker_image?

  after_update_commit :sync_runner_environment, unless: proc {|_| Rails.env.test? }
  after_rollback :delete_runner_environment, on: :create
  after_rollback :sync_runner_environment, on: %i[update destroy]

  def to_s
    name
  end

  def to_json(*_args)
    {
      id:,
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

  def self.ransackable_attributes(_auth_object = nil)
    %w[id]
  end

  private

  def set_default_values
    set_default_values_if_present(permitted_execution_time: 60, pool_size: 0)
  end

  def clean_exposed_ports
    self.exposed_ports = exposed_ports.uniq.sort
  end

  def valid_test_setup?
    if test_command? ^ testing_framework?
      errors.add(:test_command,
        I18n.t('activerecord.errors.messages.together',
          attribute: I18n.t('activerecord.attributes.execution_environment.testing_framework')))
    end
  end

  def validate_docker_image?
    # We only validate the code execution with the provided image if there is at least one container to test with.
    pool_size.positive? && docker_image.present? && !Rails.env.test? && Runner.management_active?
  end

  def working_docker_image?
    sync_runner_environment
    retries = 0
    begin
      runner = Runner.for(author, self)
      output = runner.execute_command(VALIDATION_COMMAND)
      errors.add(:docker_image, "error: #{output[:stderr]}") if output[:stderr].present?
    rescue Runner::Error => e
      # In case of an Runner::Error, we retry multiple times before giving up.
      # The time between each retry increases to allow the runner management to catch up.
      if retries < 60 && !Rails.env.test?
        retries += 1
        sleep 1.second.to_i
        retry
      elsif errors.exclude?(:docker_image)
        errors.add(:docker_image, "error: #{e}")
        raise ActiveRecord::RecordInvalid.new(self)
      end
    end
  end

  def delete_runner_environment
    Runner.strategy_class.remove_environment(self) if Runner.management_active?
  rescue Runner::Error => e
    unless errors.include?(:docker_image)
      errors.add(:docker_image, "error: #{e}")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def sync_runner_environment
    previous_saved_environment = self.class.find(id)
    Runner.strategy_class.sync_environment(previous_saved_environment) if Runner.management_active?
  rescue Runner::Error => e
    unless errors.include?(:docker_image)
      errors.add(:docker_image, "error: #{e}")
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end
end
