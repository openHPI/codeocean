FactoryBot.define do
  factory :admin, class: InternalUser do
    activated_user
    email 'admin@example.org'
    generated_user_name
    password 'admin'
    role 'admin'
    singleton_internal_user
  end

  factory :teacher, class: InternalUser do
    activated_user
    association :consumer
    generated_email
    generated_user_name
    password 'teacher'
    role 'teacher'
    singleton_internal_user
  end

  trait :activated_user do
    after(:create, &:activate!)
  end
end
