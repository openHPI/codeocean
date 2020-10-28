class RequestForCommentPolicy < ApplicationPolicy
  def create?
    everyone
  end

  def search?
    everyone
  end

  def show?
    everyone
  end

  def destroy?
    admin?
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

  def get_my_comment_requests?
    everyone
  end

  def get_rfcs_with_my_comments?
    everyone
  end
end
