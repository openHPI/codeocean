# frozen_string_literal: true

FactoryBot.define do
  factory :study_group, class: 'StudyGroup' do
    consumer
    external_id { SecureRandom.uuid }
    sequence :name do |n|
      "TestGroup#{n}"
    end
  end
end
