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
    # !! Order is important !!
    if @record.respond_to? :study_group # e.g. submission
      study_group = @record.study_group
      return false if study_group.blank?

      study_groups = [study_group]
    elsif @record.respond_to? :user # e.g. exercise
      # ToDo: Add role to study_group_membership and use for check
      study_groups = @record.user.study_groups
    elsif @record.respond_to? :users # e.g. study_group
      study_groups = [@record]
    elsif @record.respond_to? :study_groups # e.g. user
      study_groups = @record.study_groups
    else
      return false
    end

    @user.study_groups.any?{|i| study_groups.include?(i) }
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
