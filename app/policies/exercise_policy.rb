# frozen_string_literal: true

class ExercisePolicy < AdminOrAuthorPolicy
  def batch_update?
    admin?
  end

  %i[show? feedback? statistics? rfcs_for_exercise?].each do |action|
    define_method(action) { admin? || teacher_in_study_group? || teacher? && @record.public? || author? }
  end

  def study_group_dashboard?
    admin? || teacher_in_study_group?
  end

  def submission_statistics?
    admin? || teacher_in_study_group?
  end

  def detailed_statistics?
    admin?
  end

  %i[clone? destroy? edit? update?].each do |action|
    define_method(action) { admin? || teacher_in_study_group? || author? }
  end

  %i[export_external_check? export_external_confirm?].each do |action|
    define_method(action) { (admin? || teacher_in_study_group? || author?) && @user.codeharbor_link }
  end

  %i[implement? working_times? intervention? search? submit? reload?].each do |action|
    define_method(action) { everyone }
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.where('user_id = ? OR public = TRUE', @user.id)
      else
        @scope.none
      end
    end
  end
end
