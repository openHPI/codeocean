class ExercisePolicy < AdminOrAuthorPolicy
  def batch_update?
    admin?
  end

  [:show?, :study_group_dashboard?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  [:clone?, :destroy?, :edit?, :statistics?, :update?, :feedback?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:implement?, :working_times?, :intervention?, :search?, :submit?, :reload?].each do |action|
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
