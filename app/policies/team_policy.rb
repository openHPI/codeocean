class TeamPolicy < ApplicationPolicy
  [:create?, :index?, :new?].each do |action|
    define_method(action) { @user.internal? }
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    define_method(action) { admin? || member? }
  end

  def member?
    @record.members.include?(@user)
  end
  private :member?
end
