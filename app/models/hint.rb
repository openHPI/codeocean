class Hint < ActiveRecord::Base
  belongs_to :execution_environment

  validates :execution_environment_id, presence: true
  validates :locale, presence: true
  validates :message, presence: true
  validates :name, presence: true
  validates :regular_expression, presence: true

  def self.nested_resource?
    true
  end

  def to_s
    name
  end
end
