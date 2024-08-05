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

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(:study_group_memberships)
          .where(study_group_memberships: {
            study_group_id: @user.study_group_ids_as_teacher,
          })
      else
        @scope.none
      end
    end
  end
end
