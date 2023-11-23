# frozen_string_literal: true

module RedirectBehavior
  include Lti

  def redirect_after_submit
    Rails.logger.debug { "Redirecting user with score:s #{@submission.normalized_score}" }

    # Redirect to the corresponding community solution if enabled and the user is eligible.
    return redirect_to_community_solution if redirect_to_community_solution?

    # Redirect 10 percent pseudo-randomly to the feedback page.
    return redirect_to_user_feedback if !@embed_options[:disable_redirect_to_feedback] && @submission.redirect_to_feedback?

    # If the user has an own rfc, redirect to it and message them to resolve and reflect on it.
    return redirect_to_unsolved_rfc(own: true) if redirect_to_own_unsolved_rfc?

    # Otherwise, redirect to an unsolved rfc and ask for assistance.
    return redirect_to_unsolved_rfc if redirect_to_unsolved_rfc?

    # Fallback: Show the score and allow learners to return to the LTI consumer.
    redirect_to_lti_return_path
  end

  private

  def redirect_to_community_solution
    url = edit_community_solution_path(@community_solution, lock_id: @community_solution_lock.id)
    respond_to do |format|
      format.html { redirect_to(url) }
      format.json { render(json: {redirect: url}) }
    end
  end

  def redirect_to_community_solution?
    return false unless Java21Study.allow_redirect_to_community_solution?(current_user, @submission.exercise)

    @community_solution = CommunitySolution.find_by(exercise: @submission.exercise)
    return false if @community_solution.blank?

    last_contribution = CommunitySolutionContribution.where(community_solution: @community_solution).order(created_at: :asc).last

    # Only redirect if last contribution is from another user.
    eligible = last_contribution.blank? || last_contribution.user != current_user
    return false unless eligible

    # Acquire lock here! This is expensive but required for synchronization
    @community_solution_lock = ActiveRecord::Base.transaction do
      ApplicationRecord.connection.exec_query("LOCK #{CommunitySolutionLock.table_name} IN ACCESS EXCLUSIVE MODE")

      # This is returned
      CommunitySolutionLock.find_or_create_by(community_solution: @community_solution, locked_until: Time.zone.now...) do |lock|
        lock.user = current_user
        lock.locked_until = 5.minutes.from_now
      end
    end

    @community_solution_lock.user == current_user
  end

  def redirect_to_user_feedback
    uef = UserExerciseFeedback.find_by(exercise: @submission.exercise, user: current_user)
    url = if uef
            edit_exercise_user_exercise_feedback_path(uef, exercise_id: @submission.exercise)
          else
            new_exercise_user_exercise_feedback_path(exercise_id: @submission.exercise)
          end

    respond_to do |format|
      format.html { redirect_to(url) }
      format.json { render(json: {redirect: url}) }
    end
  end

  def redirect_to_unsolved_rfc(own: false)
    # Set a message that informs the user that their own RFC should be closed or help in another RFC is greatly appreciated.
    flash[:notice] = I18n.t("exercises.editor.exercise_finished_redirect_to_#{own ? 'own_' : ''}rfc")
    flash.keep(:notice)

    # Increase counter 'times_featured' in rfc
    @rfc.increment(:times_featured) unless own

    respond_to do |format|
      format.html { redirect_to(@rfc) }
      format.json { render(json: {redirect: url_for(@rfc)}) }
    end
  end

  def redirect_to_own_unsolved_rfc?
    @rfc = @submission.own_unsolved_rfc(current_user)
    @rfc.present?
  end

  def redirect_to_unsolved_rfc?
    return false if @embed_options[:disable_redirect_to_rfcs] || @embed_options[:disable_rfc]

    @rfc = @submission.unsolved_rfc(current_user)
    @rfc.present?
  end

  def redirect_to_lti_return_path
    Sentry.set_extras(
      consumers_id: current_user.consumer_id,
      external_users_id: current_user.id,
      exercises_id: @submission.exercise_id,
      session: session.to_hash,
      submission: @submission.inspect,
      params: params.as_json,
      current_user:
    )

    path = lti_return_path(submission_id: @submission.id)
    respond_to do |format|
      format.html { redirect_to(path) }
      format.json { render(json: {redirect: path}) }
    end
  end
end
