# frozen_string_literal: true

class ExternalUser < User
  validates :external_id, presence: true
  has_many :lti_parameters, dependent: :destroy

  def displayname
    name.presence || "#{model_name.human} #{id}"
  end

  def webauthn_name
    "#{consumer.name}: #{displayname}"
  end
end
