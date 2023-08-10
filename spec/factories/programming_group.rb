# frozen_string_literal: true

FactoryBot.define do
  factory :programming_group do
    exercise factory: :math

    after(:build) do |programming_group|
      # Do not change anything if users were provided explicitly
      next if programming_group.users.present?

      programming_group.users = build_list(:external_user, 2)
    end
  end
end
