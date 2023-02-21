# frozen_string_literal: true

module RedirectBehavior
  include Lti

  def redirect_after_submit
    Rails.logger.debug { "Redirecting user with score:s #{@submission.normalized_score}" }
    if @submission.normalized_score.to_d == BigDecimal('1.0')
      if redirect_to_community_solution?
        redirect_to_community_solution
        return
      end

      # if user is external and has an own rfc, redirect to it and message him to clean up and accept the answer. (we need to check that the user is external,
      # otherwise an internal user could be shown a false rfc here, since current_user.id is polymorphic, but only makes sense for external users when used with rfcs.)
      # redirect 10 percent pseudorandomly to the feedback page
      if current_user.respond_to? :external_id
        if @submission.redirect_to_feedback? && !@embed_options[:disable_redirect_to_feedback]
          clear_lti_session_data(@submission.exercise_id, @submission.user_id)
          redirect_to_user_feedback
          return
        end

        rfc = @submission.own_unsolved_rfc(current_user)
        if rfc
          # set a message that informs the user that his own RFC should be closed.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_own_rfc')
          flash.keep(:notice)

          clear_lti_session_data(@submission.exercise_id, @submission.user_id)
          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return
        end

        # else: show open rfc for same exercise if available
        rfc = @submission.unsolved_rfc(current_user)
        unless rfc.nil? || @embed_options[:disable_redirect_to_rfcs] || @embed_options[:disable_rfc]
          # set a message that informs the user that his score was perfect and help in RFC is greatly appreciated.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_rfc')
          flash.keep(:notice)

          # increase counter 'times_featured' in rfc
          rfc.increment(:times_featured)

          clear_lti_session_data(@submission.exercise_id, @submission.user_id)
          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return
        end
      end
    else
      # redirect to feedback page if score is less than 100 percent
      if @exercise.needs_more_feedback?(@submission) && !@embed_options[:disable_redirect_to_feedback]
        clear_lti_session_data(@submission.exercise_id, @submission.user_id)
        redirect_to_user_feedback
      else
        redirect_to_lti_return_path
      end
      return
    end
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
    return false unless Java21Study.allow_redirect_to_community_solution?(current_user, @exercise)

    @community_solution = CommunitySolution.find_by(exercise: @exercise)
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
    uef = UserExerciseFeedback.find_by(exercise: @exercise, user: current_user)
    url = if uef
            edit_user_exercise_feedback_path(uef)
          else
            new_user_exercise_feedback_path(user_exercise_feedback: {exercise_id: @exercise.id})
          end

    respond_to do |format|
      format.html { redirect_to(url) }
      format.json { render(json: {redirect: url}) }
    end
  end

  def redirect_to_lti_return_path
    Sentry.set_extras(
      consumers_id: @submission.user&.consumer,
      external_users_id: @submission.user_id,
      exercises_id: @submission.exercise_id,
      session: session.to_hash,
      submission: @submission.inspect,
      params: params.as_json,
      current_user:,
      lti_exercise_id: session[:lti_exercise_id],
      lti_parameters_id: session[:lti_parameters_id]
    )

    path = lti_return_path(submission_id: @submission.id)
    clear_lti_session_data(@submission.exercise_id, @submission.user_id)
    respond_to do |format|
      format.html { redirect_to(path) }
      format.json { render(json: {redirect: path}) }
    end
  end
end
