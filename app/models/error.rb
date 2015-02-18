class Error < ActiveRecord::Base
  belongs_to :execution_environment

  scope :for_execution_environment, ->(execution_environment) { where(execution_environment_id: execution_environment.id) }
  scope :grouped_by_message, -> { select('MAX(created_at) AS created_at, MAX(id) AS id, message, COUNT(id) AS count').group(:message).order('count DESC') }

  validates :execution_environment_id, presence: true
  validates :message, presence: true

  def self.nested_resource?
    true
  end
end
