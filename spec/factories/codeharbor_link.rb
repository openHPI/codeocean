# frozen_string_literal: true

FactoryBot.define do
  factory :codeharbor_link do
    user { build(:teacher) }
    push_url { 'https://push.url' }
    check_uuid_url { 'https://check-uuid.url' }
    sequence(:api_key) {|n| "api_key#{n}" }
  end
end
