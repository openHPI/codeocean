# frozen_string_literal: true

FactoryBot.define do
  factory :structured_error_attribute do
    structured_error
    error_template_attribute
    value { 'MyString' }
  end
end
