# frozen_string_literal: true

def reset_runner_strategy
  Runner.instance_variable_set :@strategy_class, nil
  Runner.instance_variable_set :@management_active, nil
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
