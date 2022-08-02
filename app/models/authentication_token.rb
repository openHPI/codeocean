# frozen_string_literal: true

require 'securerandom'

class AuthenticationToken < ApplicationRecord
  include Creation

  def self.generate!(user)
    create!(
      shared_secret: SecureRandom.hex(32),
      user: user,
      expire_at: 7.days.from_now
    )
  end
end
