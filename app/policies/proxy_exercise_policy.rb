class ProxyExercisePolicy < AdminOrAuthorPolicy
  def batch_update?
    admin?
  end

  def show?
    admin? || teacher_in_study_group? || teacher? && @record.public? || author?
  end

  [:clone?, :destroy?, :edit?, :update?].each do |action|
    define_method(action) { admin? || author?}
  end

  [:reload?].each do |action|
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
