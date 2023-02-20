# frozen_string_literal: true

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

  def teacher_in_study_group?
    # !! Order is important !!
    if @record.respond_to? :study_group # e.g. submission
      study_groups = @record.study_group
    elsif @record.respond_to? :submission # e.g. request_for_comment
      study_groups = @record.submission.study_group
    elsif @record.respond_to? :user # e.g. exercise
      study_groups = @record.author.study_groups.where(study_group_memberships: {role: :teacher})
    elsif @record.respond_to? :users # e.g. study_group
      study_groups = @record
    elsif @record.respond_to? :study_groups # e.g. user
      # Access is granted regardless of the `@record`'s role in the study group
      study_groups = @record.study_groups
    else
      return false
    end

    # Instance variable `study_groups` can be one group or an array of group
    @user.study_groups.where(study_group_memberships: {role: :teacher}).where(id: study_groups).any?
  end
  private :teacher_in_study_group?

  def initialize(user, record)
    @user = user
    @record = record
    require_user!
  end

  def require_user!
    raise Pundit::NotAuthorizedError unless @user
  end
  private :require_user!

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
      require_user!
    end

    def require_user!
      raise Pundit::NotAuthorizedError unless @user
    end
    private :require_user!
  end
end
