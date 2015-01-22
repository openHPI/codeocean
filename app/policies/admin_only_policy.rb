class AdminOnlyPolicy < ApplicationPolicy
  [:create?, :destroy?, :edit?, :index?, :new?, :show?, :update?].each do |action|
    define_method(action) { admin? }
  end
end
