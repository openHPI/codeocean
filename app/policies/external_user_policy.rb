# frozen_string_literal: true

class ExternalUserPolicy < AdminOnlyPolicy
  def index?
    admin? || teacher?
  end

  def show?
    admin? || teacher_in_study_group?
  end

  def statistics?
    admin? || teacher_in_study_group?
  end

  def tag_statistics?
    admin?
  end
end
