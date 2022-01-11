# frozen_string_literal: true

class ExternalUser < User
  validates :external_id, presence: true

  def displayname
    name.presence || "User #{id}"
  end
end
