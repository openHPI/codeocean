# frozen_string_literal: true

FactoryBot.define do
  factory :structured_error_attribute do
    association :structured_error
    association :error_template_attribute
    value { 'MyString' }
  end
end
