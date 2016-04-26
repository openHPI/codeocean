class CommentPolicy < ApplicationPolicy
  def author?
    if @record.is_a?(ActiveRecord::Relation)
      flag = true
      @record.all {|item| flag = (flag and item.author == @user)}
      flag
    else
      @user == @record.author
    end
  end
  private :author?

  def create?
    everyone
  end

  [:new?, :show?, :destroy?].each do |action|
    define_method(action) { admin? || author? }
  end

  def edit?
    admin?
  end

  def index?
    everyone
  end
end
