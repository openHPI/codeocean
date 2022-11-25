# frozen_string_literal: true

require 'securerandom'

class AuthenticationToken < ApplicationRecord
  include Creation
  belongs_to :study_group, optional: true

  def self.generate!(user, study_group)
    create!(
      shared_secret: SecureRandom.hex(32),
      user:,
      expire_at: 7.days.from_now,
      study_group:
    )
  end
end
