# frozen_string_literal: true

class ExternalUser < User
  validates :external_id, presence: true
  has_many :lti_parameters, dependent: :destroy

  def displayname
    name.presence || "User #{id}"
  end
end
