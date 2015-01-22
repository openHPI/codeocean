class ExternalUser < ActiveRecord::Base
  include User

  validates :consumer_id, presence: true
  validates :external_id, presence: true
end
