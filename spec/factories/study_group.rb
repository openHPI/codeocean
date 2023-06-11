# frozen_string_literal: true

FactoryBot.define do
  factory :study_group, class: 'StudyGroup' do
    consumer
    sequence :name do |n|
      "TestGroup#{n}"
    end
  end
end
