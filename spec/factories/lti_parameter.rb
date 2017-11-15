FactoryBot.define do

  LTI_PARAMETERS = {
      lis_result_sourcedid: "c2db0c7c-4411-4b27-a52b-ddfc3dc32065",
      lis_outcome_service_url: "http://172.16.54.235:3000/courses/0132156a-9afb-434d-83cc-704780104105/sections/21c6c6f4-1fb6-43b4-af3c-04fdc098879e/items/999b1fe6-d4b6-47b7-a577-ea2b4b1041ec/tool_grading",
      launch_presentation_return_url: "http://172.16.54.235:3000/courses/0132156a-9afb-434d-83cc-704780104105/sections/21c6c6f4-1fb6-43b4-af3c-04fdc098879e/items/999b1fe6-d4b6-47b7-a577-ea2b4b1041ec/tool_return"
  }

  factory :lti_parameter do
    association :consumer
    association :exercise, factory: :math
    association :external_user

    lti_parameters LTI_PARAMETERS

    trait :without_outcome_service_url do
      lti_parameters LTI_PARAMETERS.except(:lis_outcome_service_url)
    end
  end
end
