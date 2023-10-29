# frozen_string_literal: true

# This factory does not request the runner management as the id is already provided.
FactoryBot.define do
  factory :runner do
    runner_id { SecureRandom.uuid }
    execution_environment factory: :ruby
    contributor factory: :external_user

    after(:build) do |runner|
      runner.strategy = Runner.strategy_class.new(runner.runner_id, runner.execution_environment)
    end
  end
end
