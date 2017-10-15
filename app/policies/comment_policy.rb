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

  [:new?, :destroy?, :update?, :edit?].each do |action|
    define_method(action) { admin? || author? }
  end

  def index?
    everyone
  end
end
