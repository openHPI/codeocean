class ExternalUser < ApplicationRecord
  include User

  validates :consumer_id, presence: true
  validates :external_id, presence: true

  def displayname
    if name.blank?
      "User " + id.to_s
    else
      name
    end
  end
end
