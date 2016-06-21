class AdminOrAuthorPolicy < ApplicationPolicy
  [:create?, :index?, :new?].each do |action|
    define_method(action) { @user.internal_user? }
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    define_method(action) { admin? || author? }
  end
end
