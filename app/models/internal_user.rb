class InternalUser < ActiveRecord::Base
  include User

  authenticates_with_sorcery!

  has_and_belongs_to_many :teams

  validates :email, presence: true, uniqueness: true
  validates :password, confirmation: true, if: :password_void?, on: :update, presence: true
  validates :role, inclusion: {in: ROLES}

  def activated?
    activation_state == 'active'
  end

  def password_void?
    activation_token? || reset_password_token?
  end
  private :password_void?
end
