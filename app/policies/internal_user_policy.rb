class InternalUserPolicy < AdminOnlyPolicy
  def destroy?
    super && !@record.admin?
  end

  def show?
    super || @record == @user
  end
end
