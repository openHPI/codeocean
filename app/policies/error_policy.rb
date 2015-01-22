class ErrorPolicy < AdminOrAuthorPolicy
  def author?
    @user == @record.execution_environment.author
  end
end
