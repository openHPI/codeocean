class ExercisePolicy < AdminOrAuthorPolicy
  def author?
    @user == @record.author
  end
  private :author?

  def batch_update?
    admin?
  end

  def show?
    @user.internal_user?
  end

  [:clone?, :destroy?, :edit?, :statistics?, :update?].each do |action|
    define_method(action) { admin? || author?}
  end

  [:implement?, :submit?, :reload?].each do |action|
    define_method(action) { everyone }
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.internal_user?
        @scope.where('user_id = ? OR public = TRUE', @user.id, @user.id)
      else
        @scope.none
      end
    end
  end
end
