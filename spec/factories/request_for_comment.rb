# frozen_string_literal: true

FactoryBot.define do
  factory :rfc, class: 'RequestForComment' do
    user factory: :external_user
    exercise factory: :math
    submission { association :submission, exercise:, user:, study_group: user&.study_groups&.first }
    file
    sequence :question do |n|
      "test question #{n}"
    end

    factory :rfc_with_comment, class: 'RequestForComment' do
      after(:create) do |rfc|
        rfc.file = rfc.submission.files.first
        Comment.create(file: rfc.file, user: rfc.user, row: 1, text: "comment for rfc #{rfc.question}")
        rfc.submission.study_group_id = rfc.user.current_study_group_id
      end
    end
  end
end
