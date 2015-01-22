class ConsumerPolicy < AdminOnlyPolicy
  def show?
    super || @user.consumer == @record
  end
end
