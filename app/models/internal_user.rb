class InternalUser < ActiveRecord::Base
  include User

  authenticates_with_sorcery!

  validates :email, presence: true, uniqueness: true
  validates :password, confirmation: true, on: :update, presence: true, unless: :activated?
  validates :role, inclusion: {in: ROLES}

  def activated?
    activation_state == 'active'
  end
end
