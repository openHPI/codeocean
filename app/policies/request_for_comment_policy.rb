# frozen_string_literal: true

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

  def clear_question?
    admin? || teacher_in_study_group?
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

  def my_comment_requests?
    everyone
  end

  def rfcs_with_my_comments?
    everyone
  end
end
