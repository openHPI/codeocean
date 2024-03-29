# frozen_string_literal: true

FactoryBot.define do
  factory :error_template do
    execution_environment factory: :ruby
    name { 'MyString' }
    signature { 'MyString' }
  end
end
