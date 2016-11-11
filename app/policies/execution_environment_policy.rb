class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  def author?
    @user == @record.author
  end
  private :author?

  [:execute_command?, :shell?, :statistics?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:create?, :index?, :new?].each do |action|
    define_method(action) { admin? || teacher? }
  end
end
