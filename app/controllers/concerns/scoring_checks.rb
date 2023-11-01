# frozen_string_literal: true

module ScoringChecks
  def check_submission(submit_info)
    lti_check = check_lti_transmission(submit_info[:users])
    # If we got a `:scoring_failure` from the LTI check, we want to display this message exclusively.
    return [lti_check] if lti_check.present? && lti_check[:status] == :scoring_failure

    # Otherwise, the score was sent successfully for the current user,
    # or it was not attempted for any user (i.e., no `lis_outcome_service` was available).
    # In any way, we want to check for further conditions and return all messages.
    [
      lti_check,
      check_scoring_too_late(submit_info),
      check_full_score,
    ]
  end

  private

  def check_full_score
    # The submission was not scored with the full score, hence the exercise is not finished yet.
    return unless @submission.full_score?

    {status: :exercise_finished, url: finalize_submission_path(@submission)}
  end

  def check_lti_transmission(scored_users)
    if scored_users[:all] == scored_users[:error] || scored_users[:error].include?(current_user)
      # The score was not sent for any user or sending the score for the current user failed.
      # In the latter case, we want to encourage the current user to reopen the exercise through the LMS.
      # Hence, we always display the most severe error message.
      {status: :scoring_failure}
    elsif scored_users[:all] != scored_users[:success] && scored_users[:success].include?(current_user)
      # The score was sent successfully for current user.
      # However, at the same time, the transmission failed for some other users.
      # This could either be due to a temporary network error, which is unlikely, or a more "permanent" error.
      # Permanent errors would be that the deadline has passed on the LMS (which would then not provide a `lis_outcome_service`),
      # working together with an internal user, or with someone who has never opened the exercise before.
      {status: :not_for_all_users_submitted, failed_users: scored_users[:error].map(&:displayname).join(', ')}
    end
  end

  def check_scoring_too_late(submit_info)
    # The submission was either performed before any deadline or no deadline was configured at all for the current exercise.
    return if %i[within_grace_period after_late_deadline].exclude? submit_info[:deadline]
    # The `lis_outcome_service` was not provided by the LMS, hence we were not able to send any score.
    return if submit_info[:users][:unsupported].include?(current_user)

    {status: :scoring_too_late, score_sent: (submit_info[:score][:sent] * 100).to_i}
  end
end
