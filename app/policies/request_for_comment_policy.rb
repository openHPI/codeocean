class RequestForCommentPolicy < ApplicationPolicy


  def create?
    everyone
  end

  def show?
    everyone
  end

  [:destroy?].each do |action|
    define_method(action) { admin? }
  end

  def edit?
    admin?
  end

  def index?
    everyone
  end
end
