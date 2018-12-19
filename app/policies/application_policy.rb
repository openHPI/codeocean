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
