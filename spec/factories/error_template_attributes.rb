# frozen_string_literal: true

FactoryBot.define do
  factory :error_template_attribute do
    key { 'MyString' }
    regex { 'MyString' }
  end
end
