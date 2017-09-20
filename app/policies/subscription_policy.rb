class SubscriptionPolicy < ApplicationPolicy
  def create?
    everyone
  end

  def destroy?
    author? || admin?
  end

  def show_error?
    everyone
  end

  def author?
    @user == @record.user
  end
  private :author?
end
