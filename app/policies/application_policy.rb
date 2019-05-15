class ApplicationPolicy
  def admin?
    @user.admin?
  end
  private :admin?

  def teacher?
    @user.teacher?
  end
  private :teacher?

  def author?
    @user == @record.author
  end
  private :author?

  def everyone
    # As the ApplicationController forces to have any authorization, `everyone` here means `every user logged in`
    true
  end
  private :everyone

  def no_one
    false
  end
  private :no_one

  def everyone_in_study_group
    if @record.respond_to? :study_group # e.g. submission
      study_group = @record.study_group
      return false if study_group.blank?

      users_in_same_study_group = study_group.users
    else # e.g. exercise
      study_groups = @record.user.study_groups
      users_in_same_study_group = study_groups.collect{ |study_group|
        study_group.users}.flatten
    end

    users_in_same_study_group.include? @user
  end
  private :everyone_in_study_group

  def teacher_in_study_group?
    teacher? && everyone_in_study_group
  end
  private :teacher_in_study_group?

  def initialize(user, record)
    @user = user
    @record = record
    require_user!
  end

  def require_user!
    fail Pundit::NotAuthorizedError unless @user
  end
  private :require_user!

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
      require_user!
    end

    def require_user!
      fail Pundit::NotAuthorizedError unless @user
    end
    private :require_user!
  end
end
