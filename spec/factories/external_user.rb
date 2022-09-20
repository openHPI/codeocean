# frozen_string_literal: true

FactoryBot.define do
  factory :external_user do
    association :consumer
    generated_email
    external_id { SecureRandom.uuid }
    generated_user_name
    singleton_external_user
    member_of_study_group
    transient do
      teacher_in_study_group { false }
    end
  end
end
