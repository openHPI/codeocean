# frozen_string_literal: true

FactoryBot.define do
  factory :submission do
    cause { 'save' }
    created_by_external_user
    exercise factory: :math

    after(:create) do |submission|
      submission.exercise.files.editable.visible.each do |file|
        submission.add_file(content: file.content, file_id: file.id)
      end

      # Do not change anything if a study group was provided explicitly or user has no study groups
      next if submission.study_group.present? || submission.users.first.study_groups.blank?

      submission.update!(study_group: submission.users.first.study_groups.first)
    end
  end
end
