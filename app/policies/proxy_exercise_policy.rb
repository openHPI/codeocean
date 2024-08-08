# frozen_string_literal: true

class ProxyExercisePolicy < AdminOrAuthorPolicy
  def batch_update?
    admin?
  end

  def show?
    admin? || teacher_in_study_group? || (teacher? && @record.public?) || author?
  end

  %i[clone? destroy? edit? update?].each do |action|
    define_method(action) { admin? || author? || teacher_in_study_group? }
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.distinct
          .joins('LEFT OUTER JOIN study_group_memberships ON proxy_exercises.user_type = study_group_memberships.user_type AND proxy_exercises.user_id = study_group_memberships.user_id')
          # The proxy_exercise's author is a teacher in the study group
          .where(study_group_memberships: {role: StudyGroupMembership.roles[:teacher]})
          # The current user is a teacher in the *same* study group
          .where(study_group_memberships: {study_group_id: @user.study_group_ids_as_teacher})
          .or(@scope.distinct.where(user: @user))
          .or(@scope.distinct.where(public: true))
      else
        @scope.none
      end
    end
  end
end
