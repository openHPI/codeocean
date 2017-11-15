FactoryBot.define do
  factory :external_user do
    association :consumer
    generated_email
    external_id { SecureRandom.uuid }
    generated_user_name
    singleton_external_user
  end
end
