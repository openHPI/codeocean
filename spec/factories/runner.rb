# frozen_string_literal: true

# This factory does not request the runner management as the id is already provided.
FactoryBot.define do
  factory :runner do
    sequence(:runner_id) {|n| "test-runner-id-#{n}" }
    association :execution_environment, factory: :ruby
    association :user, factory: :external_user
    waiting_time { 1.0 }
  end
end
