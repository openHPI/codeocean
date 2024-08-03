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

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(:study_group_memberships)
          .where(study_group_memberships: {
            study_group_id: @user.study_group_memberships
                                .where(study_group_memberships: {role: StudyGroupMembership.roles[:teacher]})
                                .select(:study_group_id),
          })
      else
        @scope.none
      end
    end
  end
end
