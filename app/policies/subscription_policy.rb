# frozen_string_literal: true

class SubscriptionPolicy < ApplicationPolicy
  def create?
    everyone
  end

  def destroy?
    author? || admin?
  end

  def author?
    @user == @record.user
  end
  private :author?
end
