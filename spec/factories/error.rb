FactoryBot.define do
  factory :error, class: Error do
    association :execution_environment, factory: :ruby
    message "exercise.rb:4:in `<main>': undefined local variable or method `foo' for main:Object (NameError)"
  end
end
