# frozen_string_literal: true

class InternalUser < User
  authenticates_with_sorcery!

  attr_accessor :validate_password

  validates :email, presence: true, uniqueness: true
  validates :password, confirmation: true, if: -> { password_void? && validate_password? }, on: :update, presence: true
  validates :role, inclusion: {in: ROLES}

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

  def teacher?
    role == 'teacher'
  end

  def displayname
    name
  end
end
