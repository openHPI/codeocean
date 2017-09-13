class SubscriptionPolicy < ApplicationPolicy
  def create?
    everyone
  end
end
