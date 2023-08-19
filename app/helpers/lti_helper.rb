# frozen_string_literal: true

module LtiHelper
  # Checks for support of the LTI outcome service for the given exercise and user.
  # If the user passed is not the `current_user`, a study group id **must** be passed as well.
  def lti_outcome_service?(exercise, user, study_group_id = user.current_study_group_id)
    return false unless user.external_user?

    lis_outcome_service_parameters(exercise, user, study_group_id).present?
  end

  private

  def lis_outcome_service_parameters(exercise, external_user, study_group_id)
    external_user.lti_parameters.lis_outcome_service_url?.find_by(exercise:, study_group_id:)
  end
end
