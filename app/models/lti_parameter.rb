class LtiParameter < ActiveRecord::Base
  scope :lis_outcome_service_url?, -> {
    where("lti_parameters.lti_parameters ? 'lis_outcome_service_url'")
  }
end