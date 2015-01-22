class Consumer < ActiveRecord::Base
  has_many :users

  scope :with_users, -> { where('id IN (SELECT consumer_id FROM internal_users)') }

  validates :name, presence: true
  validates :oauth_key, presence: true, uniqueness: true
  validates :oauth_secret, presence: true

  def to_s
    name
  end
end
