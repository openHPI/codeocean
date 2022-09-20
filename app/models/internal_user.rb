# frozen_string_literal: true

require 'zxcvbn'

class InternalUser < User
  authenticates_with_sorcery!

  attr_accessor :validate_password

  validates :email, presence: true, uniqueness: true
  validates :password, confirmation: true, if: -> { password_void? && validate_password? }, on: :update, presence: true
  validate :password_strength, if: -> { password_void? && validate_password? }, on: :update

  accepts_nested_attributes_for :study_group_memberships

  def activated?
    activation_state == 'active'
  end

  def password_void?
    activation_token? || reset_password_token?
  end
  private :password_void?

  def validate_password?
    return true if @validate_password.nil?

    @validate_password
  end
  private :validate_password?

  def password_strength
    result = Zxcvbn.test(password, [email, name, 'CodeOcean'])
    errors.add(:password, :weak) if result.score < 4
  end

  def displayname
    name
  end
end
