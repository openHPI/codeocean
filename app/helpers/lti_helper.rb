module LtiHelper
  def lti_outcome_service?(exercise_id, external_user_id, consumer_id)
    return false if external_user_id == '' || consumer_id == ''

    lti_parameters = LtiParameter.where(consumers_id: consumer_id,
                                       external_users_id: external_user_id,
                                       exercises_id: exercise_id).lis_outcome_service_url?
    !lti_parameters.nil? && lti_parameters.size > 0
  end
end