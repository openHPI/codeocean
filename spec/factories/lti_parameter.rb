# frozen_string_literal: true

FactoryBot.define do
  lti_params = {
    lis_result_sourcedid: 'c2db0c7c-4411-4b27-a52b-ddfc3dc32065',
      lis_outcome_service_url: 'https://172.16.54.235:3000/courses/0132156a-9afb-434d-83cc-704780104105/sections/21c6c6f4-1fb6-43b4-af3c-04fdc098879e/items/999b1fe6-d4b6-47b7-a577-ea2b4b1041ec/tool_grading',
      launch_presentation_return_url: 'https://172.16.54.235:3000/courses/0132156a-9afb-434d-83cc-704780104105/sections/21c6c6f4-1fb6-43b4-af3c-04fdc098879e/items/999b1fe6-d4b6-47b7-a577-ea2b4b1041ec/tool_return',
  }.freeze

  factory :lti_parameter do
    exercise factory: :math
    external_user

    lti_parameters { lti_params }

    after(:create) do |lti_parameter|
      # Do not change anything if a study group was provided explicitly or user has no study groups
      next if lti_parameter.study_group.present? || lti_parameter.external_user.study_groups.blank?

      lti_parameter.update!(study_group: lti_parameter.external_user.study_groups.first)
    end

    trait :without_outcome_service_url do
      lti_parameters { lti_params.except(:lis_outcome_service_url) }
    end

    trait :without_return_url do
      lti_parameters { lti_params.except(:launch_presentation_return_url) }
    end
  end
end
