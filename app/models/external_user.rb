# frozen_string_literal: true

class ExternalUser < User
  validates :external_id, presence: true, uniqueness: {scope: :consumer_id}
  has_many :lti_parameters, dependent: :destroy

  def displayname
    name.presence || "#{model_name.human} #{id}"
  end

  def soft_delete
    update!(name: 'Deleted User', email: nil, deleted_at: Time.zone.now)
  end

  def webauthn_name
    "#{consumer.name}: #{displayname}"
  end
end
