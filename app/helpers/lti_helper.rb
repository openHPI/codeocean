module LtiHelper
  def lti_outcome_service?(exercise_id)
    #Todo replace session with lti_parameter /done
    lti_parameters = LtiParameter.where(consumers_id: session[:consumer_id],
                                       external_user_id: session[:external_user_id],
                                       exercises_id: exercise_id).lis_outcome_service_url?
    !lti_parameters.nil? && lti_parameters.size > 0
    # session[:lti_parameters].try(:has_key?, 'lis_outcome_service_url')
  end
end