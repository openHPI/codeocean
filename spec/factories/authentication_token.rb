# frozen_string_literal: true

FactoryBot.define do
  factory :authentication_token, class: 'AuthenticationToken' do
    created_by_external_user
    shared_secret { SecureRandom.hex(32) }
    expire_at { 7.days.from_now }

    after(:create) do |auth_token|
      # Do not change anything if a study group was provided explicitly or user has no study groups
      next if auth_token.study_group_id.present? || auth_token.user.study_groups.blank?

      auth_token.update!(study_group_id: auth_token.user.study_groups.first.id)
    end

    trait :invalid do
      expire_at { 8.days.ago }
    end
  end
end
