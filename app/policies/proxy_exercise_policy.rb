# frozen_string_literal: true

class ProxyExercisePolicy < AdminOrAuthorPolicy
  def batch_update?
    admin?
  end

  def show?
    admin? || teacher_in_study_group? || (teacher? && @record.public?) || author?
  end

  %i[clone? destroy? edit? update?].each do |action|
    define_method(action) { admin? || author? }
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
