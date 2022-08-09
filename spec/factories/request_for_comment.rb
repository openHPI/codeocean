# frozen_string_literal: true

FactoryBot.define do
  factory :rfc, class: 'RequestForComment' do
    association :user, factory: :external_user
    association :submission
    association :exercise, factory: :dummy
    association :file
    sequence :question do |n|
      "test question #{n}"
    end

    factory :rfc_with_comment, class: 'RequestForComment' do
      after(:create) do |rfc|
        rfc.file = rfc.submission.files.first
        Comment.create(file: rfc.file, user: rfc.user, row: 1, text: "comment for rfc #{rfc.question}")
      end
    end
  end
end
