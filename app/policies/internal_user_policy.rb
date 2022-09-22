# frozen_string_literal: true

class InternalUserPolicy < AdminOnlyPolicy
  def destroy?
    admin? && !@record.admin?
  end

  def index?
    admin? || teacher?
  end

  def show?
    admin? || @record == @user || teacher_in_study_group?
  end
end
