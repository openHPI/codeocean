# frozen_string_literal: true

FactoryBot.define do
  factory :remote_evaluation_mapping, class: 'RemoteEvaluationMapping' do
    created_by_external_user
    validation_token { SecureRandom.urlsafe_base64 }
    exercise factory: :math

    after(:create) do |remote_evaluation_mapping|
      # Do not change anything if a study group was provided explicitly or user has no study groups
      unless remote_evaluation_mapping.study_group_id.present? || remote_evaluation_mapping.user.study_groups.blank?
        remote_evaluation_mapping.update!(study_group_id: remote_evaluation_mapping.user.study_groups.first.id)
      end

      pg = remote_evaluation_mapping.user.programming_groups.find_by(exercise: remote_evaluation_mapping.exercise)
      # Do not change anything if a programming group was provided explicitly or user has no programming group
      unless remote_evaluation_mapping.programming_group_id.present? || pg.blank?
        remote_evaluation_mapping.update!(programming_group_id: pg.id)
      end
    end
  end
end
