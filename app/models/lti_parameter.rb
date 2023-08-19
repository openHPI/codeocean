# frozen_string_literal: true

class LtiParameter < ApplicationRecord
  belongs_to :exercise
  belongs_to :external_user
  belongs_to :study_group, optional: true
  delegate :consumer, to: :external_user

  validates :external_user_id, uniqueness: {scope: %i[study_group_id exercise_id]}

  scope :lis_outcome_service_url?, lambda {
    where("lti_parameters.lti_parameters ? 'lis_outcome_service_url'")
  }
end
