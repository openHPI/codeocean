# frozen_string_literal: true

def reset_runner_strategy
  Runner.remove_instance_variable(:@strategy_class) if Runner.instance_variable_defined?(:@strategy_class)
  Runner.remove_instance_variable(:@management_active) if Runner.instance_variable_defined?(:@management_active)
end

RSpec.configure do |config|
  # When starting the application, the environment is initialized with the default runner strategy:
  # `Runner.strategy_class.initialize_environment` is called in `config/application.rb`.
  config.before(:suite) do
    reset_runner_strategy
  end

  # After each test, we reset the memorized runner strategy to the default (similar to the database cleaner).
  config.append_after do
    reset_runner_strategy
  end
end
