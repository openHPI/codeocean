class RequestForCommentPolicy < ApplicationPolicy
  def author?
    @user == @record.author
  end
  private :author?

  def create?
    everyone
  end

  def search?
    everyone
  end

  def show?
    everyone
  end

  [:destroy?].each do |action|
    define_method(action) { admin? }
  end

  def mark_as_solved?
    admin? || author?
  end

  def set_thank_you_note?
    admin? || author?
  end

  def edit?
    admin?
  end

  def index?
    everyone
  end

  def create_comment_exercise?
    everyone
  end
end
