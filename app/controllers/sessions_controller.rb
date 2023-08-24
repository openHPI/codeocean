# frozen_string_literal: true

class SessionsController < ApplicationController
  include Lti

  %i[require_oauth_parameters require_valid_consumer_key require_valid_oauth_signature require_unique_oauth_nonce
     set_current_user require_valid_exercise_token set_study_group_membership set_embedding_options].each do |method_name|
    before_action(method_name, only: :create_through_lti)
  end

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token, only: :create_through_lti
  after_action :set_sentry_context

  def new
    redirect_to(:root, alert: t('shared.already_signed_in')) if current_user
  end

  def create_through_lti
    session.delete(:pg_id) # Remove any previous pg_id from the session
    store_lti_session_data(params)
    store_nonce(params[:oauth_nonce])
    if params[:custom_redirect_target]
      redirect_to(URI.parse(params[:custom_redirect_target].to_s).path)
    elsif PairProgramming23Study.participate?
      redirect_to(new_exercise_programming_group_path(@exercise))
    else
      redirect_to(implement_exercise_path(@exercise),
        notice: t("sessions.create_through_lti.session_#{lti_outcome_service?(@exercise, current_user) ? 'with' : 'without'}_outcome",
          consumer: @consumer))
    end
  end

  def create
    if login(params[:email], params[:password], params[:remember_me])
      # We set the user's default study group to the "internal" group (no external id) for the given consumer.
      session[:study_group_id] = current_user.study_groups.find_by(external_id: nil)&.id
      redirect_back_or_to(:root, notice: t('.success'))
    else
      flash.now[:danger] = t('.failure')
      render(:new)
    end
  end

  def destroy_through_lti
    @submission = Submission.find(params[:submission_id])
    authorize(@submission, :show?)
    lti_parameter = current_user.lti_parameters.find_by(exercise: @submission.exercise, study_group_id: current_user.current_study_group_id)
    @url = consumer_return_url(build_tool_provider(consumer: current_user.consumer, parameters: lti_parameter&.lti_parameters))
  end

  def destroy
    if current_user&.external_user?
      session.delete(:external_user_id)
      session.delete(:study_group_id)
      session.delete(:embed_options)
      session.delete(:pg_id)

      # In case we have another session as an internal user, we set the study group for this one
      internal_user = find_or_login_current_user
      if internal_user.present?
        session[:study_group_id] = internal_user.study_groups.find_by(external_id: nil)&.id
      end
    else
      logout
    end
    redirect_to(:root, notice: t('.success'))
  end
end
