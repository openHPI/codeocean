# frozen_string_literal: true

FactoryBot.define do
  factory :admin, class: 'InternalUser' do
    activated_user
    association :consumer
    email { 'admin@example.org' }
    generated_user_name
    password { 'admin' }
    platform_admin { true }
    singleton_internal_user
    member_of_study_group
    transient do
      teacher_in_study_group { true }
    end
  end

  factory :teacher, class: 'InternalUser' do
    activated_user
    association :consumer
    generated_email
    generated_user_name
    password { 'teacher' }
    platform_admin { false }
    singleton_internal_user
    member_of_study_group
    transient do
      teacher_in_study_group { true }
    end
  end

  factory :learner, class: 'InternalUser' do
    activated_user
    association :consumer
    generated_email
    generated_user_name
    password { 'learner' }
    platform_admin { false }
    singleton_internal_user
    member_of_study_group
    transient do
      teacher_in_study_group { false }
    end
  end

  trait :activated_user do
    after(:create, &:activate!)
  end
end
