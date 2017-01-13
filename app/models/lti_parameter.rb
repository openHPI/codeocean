class LtiParameter < ActiveRecord::Base
  belongs_to :consumer, foreign_key: "consumers_id"
  belongs_to :exercise, foreign_key: "exercises_id"
  belongs_to :external_user, foreign_key: "external_users_id"

  scope :lis_outcome_service_url?, -> {
    where("lti_parameters.lti_parameters ? 'lis_outcome_service_url'")
  }
end