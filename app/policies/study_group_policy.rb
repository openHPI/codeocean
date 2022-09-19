# frozen_string_literal: true

class StudyGroupPolicy < AdminOnlyPolicy
  def index?
    admin? || teacher?
  end

  %i[show? edit? update? stream_la? set_as_current?].each do |action|
    define_method(action) { admin? || teacher_in_study_group? }
  end

  def destroy?
    # A default study group should not get deleted without the consumer
    return no_one if @record.external_id.blank?

    admin? || teacher_in_study_group?
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(:study_group_memberships).where(study_group_memberships: {user: @user, role: StudyGroupMembership.roles[:teacher]})
      else
        @scope.none
      end
    end
  end
end
