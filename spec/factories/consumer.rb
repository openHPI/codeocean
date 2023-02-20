# frozen_string_literal: true

FactoryBot.define do
  factory :consumer do
    name { 'openHPI' }
    rfc_visibility { 'all' }
    singleton_consumer
  end

  trait :singleton_consumer do
    initialize_with do
      Consumer.find_or_initialize_by(name:) do |consumer|
        consumer.oauth_key = SecureRandom.hex
        consumer.oauth_secret = SecureRandom.hex
      end
    end
  end
end
