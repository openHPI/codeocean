FactoryBot.define do
  factory :consumer do
    name 'openHPI'
    oauth_key { SecureRandom.hex }
    oauth_secret { SecureRandom.hex }
    singleton_consumer
  end

  trait :singleton_consumer do
    initialize_with { Consumer.where(name: name).first_or_create }
  end
end
