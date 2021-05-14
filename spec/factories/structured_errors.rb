# frozen_string_literal: true

FactoryBot.define do
  factory :structured_error do
    association :error_template
    association :submission
  end
end
