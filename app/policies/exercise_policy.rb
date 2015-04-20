class ExercisePolicy < AdminOrAuthorPolicy
  def author?
    @user == @record.author
  end
  private :author?

  def batch_update?
    admin?
  end

  [:clone?, :destroy?, :edit?, :show?, :statistics?, :update?].each do |action|
    define_method(action) { admin? || author? || team_member? }
  end

  [:implement?, :submit?, :reload?].each do |action|
    define_method(action) { everyone }
  end

  def team_member?
    @record.team.try(:members, []).include?(@user) if @record.team
  end
  private :team_member?

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      elsif @user.internal_user?
        @scope.where('user_id = ? OR public = TRUE OR (team_id IS NOT NULL AND team_id IN (SELECT t.id FROM teams t JOIN internal_users_teams iut ON t.id = iut.team_id WHERE iut.internal_user_id = ?))', @user.id, @user.id)
      else
        @scope.none
      end
    end
  end
end
