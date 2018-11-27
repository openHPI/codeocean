class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  [:execute_command?, :shell?, :statistics?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:show?, :index?, :new?].each do |action|
    define_method(action) { admin? || teacher? }
  end
end
