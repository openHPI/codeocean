# frozen_string_literal: true

FactoryBot.define do
  factory :authentication_token, class: 'AuthenticationToken' do
    created_by_external_user
    shared_secret { SecureRandom.hex(32) }
    expire_at { 7.days.from_now }

    trait :invalid do
      expire_at { 8.days.ago }
    end
  end
end
