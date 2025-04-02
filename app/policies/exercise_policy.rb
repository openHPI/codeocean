# frozen_string_literal: true

class ExercisePolicy < AdminOrAuthorPolicy
  def batch_update?
    admin?
  end

  %i[show? feedback? statistics? external_user_statistics? rfcs_for_exercise?].each do |action|
    define_method(action) { admin? || teacher_in_study_group? || (teacher? && @record.public?) || author? }
  end

  def study_group_dashboard?
    admin? || teacher_in_study_group?
  end

  def detailed_statistics?
    admin?
  end

  %i[clone? destroy? edit? update?].each do |action|
    define_method(action) { admin? || teacher_in_study_group? || author? }
  end

  %i[export_external_check? export_external_confirm?].each do |action|
    define_method(action) { Pundit.policy(@user, CodeharborLink).enabled? && (admin? || teacher_in_study_group? || author?) && @user.codeharbor_link }
  end

  %i[implement? working_times? intervention? reload?].each do |action|
    define_method(action) do
      return no_one unless @record.files.any? {|f| f.hidden == false } && @record.execution_environment.present?

      admin? || teacher_in_study_group? || author? || (everyone && !@record.unpublished?)
    end
  end

  def programming_groups_for_exercise?
    admin?
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.distinct
          .joins('LEFT OUTER JOIN study_group_memberships ON exercises.user_type = study_group_memberships.user_type AND exercises.user_id = study_group_memberships.user_id')
          # The exercise's author is a teacher in the study group
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

  class WithProgrammingGroupsScope < Scope
    def resolve
      if @user.admin?
        @scope.where(id: ProgrammingGroup.select(:exercise_id))
      elsif @user.teacher?
        @scope.where(id: ProgrammingGroupPolicy::Scope.new(@user, ProgrammingGroup).resolve.distinct.pluck(:exercise_id))
      else
        @scope.none
      end
    end
  end

  class WithSubmissionsScope < Scope
    def resolve
      if @user.admin?
        @scope.where(id: Submission.select(:exercise_id))
      elsif @user.teacher?
        @scope.where(id: SubmissionPolicy::Scope.new(@user, Submission).resolve.distinct.pluck(:exercise_id))
      else
        @scope.none
      end
    end
  end
end
