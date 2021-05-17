# frozen_string_literal: true

require 'oauth/request_proxy/action_controller_request' # Rails 5 changed `Rack::Request` to `ActionDispatch::Request`

module LtiHelper
  def lti_outcome_service?(exercise_id, external_user_id)
    return false if external_user_id == ''

    lti_parameters = LtiParameter.where(external_users_id: external_user_id,
      exercises_id: exercise_id).lis_outcome_service_url?.last
    !lti_parameters.nil? && lti_parameters.present?
  end
end
