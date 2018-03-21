require File.expand_path('../../../lib/active_model/validations/boolean_presence_validator', __FILE__)

class ExecutionEnvironment < ActiveRecord::Base
  include Creation
  include DefaultValues

  VALIDATION_COMMAND = 'whoami'

  after_initialize :set_default_values

  has_many :exercises
  belongs_to :file_type
  has_many :hints
  has_many :error_templates
  has_many :programming_languages, dependent: :destroy

  scope :with_exercises, -> { where('id IN (SELECT execution_environment_id FROM exercises)') }

  validate :valid_test_setup?
  validate :working_docker_image?, if: :validate_docker_image?
  validates :docker_image, presence: true
  validates :memory_limit, numericality: {greater_than_or_equal_to: DockerClient::MINIMUM_MEMORY_LIMIT, only_integer: true}, presence: true
  validates :network_enabled, boolean_presence: true
  validates :name, presence: true
  validates :permitted_execution_time, numericality: {only_integer: true}, presence: true
  validates :pool_size, numericality: {only_integer: true}, presence: true
  validates :run_command, presence: true

  validates :programming_languages, presence: true
  accepts_nested_attributes_for :programming_languages, reject_if: :all_blank, allow_destroy: true

  def set_default_values
    set_default_values_if_present(permitted_execution_time: 60, pool_size: 0)
  end
  private :set_default_values

  def to_s
    name
  end

  def valid_test_setup?
    if test_command? ^ testing_framework?
      errors.add(:test_command, I18n.t('activerecord.errors.messages.together', attribute: I18n.t('activerecord.attributes.execution_environment.testing_framework')))
    end
  end
  private :valid_test_setup?

  def validate_docker_image?
    docker_image.present? && !Rails.env.test?
  end
  private :validate_docker_image?

  def working_docker_image?
    DockerClient.pull(docker_image) unless DockerClient.find_image_by_tag(docker_image).blank?
    output = DockerClient.new(execution_environment: self).execute_arbitrary_command(VALIDATION_COMMAND)
    errors.add(:docker_image, "error: #{output[:stderr]}") if output[:stderr].present?
  rescue DockerClient::Error => error
    errors.add(:docker_image, "error: #{error}")
  end
  private :working_docker_image?
end
