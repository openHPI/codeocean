class CommentPolicy < ApplicationPolicy
  def author?
    @user == @record.author
  end
  private :author?

  def create?
    everyone
  end

  def show?
    everyone
  end

  [:new?, :destroy?].each do |action|
    define_method(action) { admin? || author? }
  end

  def edit?
    admin?
  end

  def index?
    everyone
  end
end
