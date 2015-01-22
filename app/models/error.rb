class Error < ActiveRecord::Base
  belongs_to :execution_environment

  scope :for_execution_environment, ->(execution_environment) do
    Error.find_by_sql("SELECT MAX(created_at) AS created_at, MAX(id) AS id, message, COUNT(*) AS count FROM errors WHERE #{sanitize_sql_hash_for_conditions(execution_environment_id: execution_environment.id)} GROUP BY message ORDER BY count DESC")
  end

  validates :execution_environment_id, presence: true
  validates :message, presence: true

  def self.nested_resource?
    true
  end
end
