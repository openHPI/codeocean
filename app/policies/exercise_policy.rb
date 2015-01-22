class ExercisePolicy < AdminOrAuthorPolicy
  def author?
    @user == @record.author
  end
  private :author?

  [:clone?, :statistics?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:implement?, :submit?].each do |action|
    define_method(action) { everyone }
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      else
        @scope.where("user_id = #{@user.id} OR public = TRUE")
      end
    end
  end
end
