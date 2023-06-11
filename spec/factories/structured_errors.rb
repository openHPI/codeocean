# frozen_string_literal: true

FactoryBot.define do
  factory :structured_error do
    error_template
    submission
  end
end
