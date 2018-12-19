class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  [:execute_command?, :shell?, :statistics?, :show?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:index?].each do |action|
    define_method(action) { admin? || teacher? }
  end
end
