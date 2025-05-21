# frozen_string_literal: true

FactoryBot.define do
  factory :rfc, class: 'RequestForComment' do
    user factory: :external_user
    exercise factory: :math
    submission { association :submission, exercise:, user:, study_group: user&.study_groups&.first, cause: 'requestComments' }
    file { submission.files.first }
    sequence :question do |n|
      "test question #{n}"
    end

    factory :rfc_with_comment, class: 'RequestForComment' do
      after(:create) do |rfc|
        create(:comment, file: rfc.file)
      end
    end
  end
end
