class SessionsController < ApplicationController
  include Lti

  [:require_oauth_parameters, :require_valid_consumer_key, :require_valid_oauth_signature, :require_unique_oauth_nonce, :set_current_user, :require_valid_exercise_token].each do |method_name|
    before_action(method_name, only: :create_through_lti)
  end

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token, only: :create_through_lti

  def create
    if login(params[:email], params[:password], params[:remember_me])
      redirect_back_or_to(:root, notice: t('.success'))
    else
      flash.now[:danger] = t('.failure')
      render(:new)
    end
  end

  def create_through_lti
    store_lti_session_data(consumer: @consumer, parameters: params)
    store_nonce(params[:oauth_nonce])
    redirect_to(implement_exercise_path(@exercise),
                notice: t("sessions.create_through_lti.session_#{lti_outcome_service?(@exercise.id, @current_user.id , @consumer.id) ? 'with' : 'without'}_outcome",
                consumer: @consumer))
  end

  def destroy
    if current_user.external_user?
      clear_lti_session_data
    else
      logout
    end
    redirect_to(:root, notice: t('.success'))
  end

  def destroy_through_lti
    @submission = Submission.find(params[:submission_id])
    clear_lti_session_data(@submission.exercise_id, @submission.user_id, params[:consumer_id])
  end

  def new
    redirect_to(:root, alert: t('shared.already_signed_in')) if current_user
  end
end
