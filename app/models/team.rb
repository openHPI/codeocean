class Team < ActiveRecord::Base
  has_and_belongs_to_many :internal_users
  alias_method :members, :internal_users

  validates :name, presence: true

  def to_s
    name
  end
end
