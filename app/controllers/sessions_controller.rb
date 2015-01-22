class SessionsController < ApplicationController
  include Lti

  [:require_oauth_parameters, :require_valid_consumer_key, :require_valid_oauth_signature, :require_valid_exercise_token].each do |method_name|
    before_action(method_name, only: :create_through_lti)
  end

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token, only: :create_through_lti

  def create
    if user = login(params[:email], params[:password], params[:remember_me])
      redirect_back_or_to(:root, notice: t('.success'))
    else
      flash.now[:danger] = t('.failure')
      render(:new)
    end
  end

  def create_through_lti
    set_current_user
    store_lti_session_data(consumer: @consumer, parameters: params)
    store_nonce(params[:oauth_nonce])
    flash[:notice] = I18n.t("sessions.create_through_lti.session_#{lti_outcome_service? ? 'with' : 'without'}_outcome", consumer: @consumer)
    redirect_to(implement_exercise_path(@exercise.id))
  end

  def destroy
    if current_user.external?
      clear_lti_session_data
    else
      logout
    end
    redirect_to(:root, notice: t('.success'))
  end

  def destroy_through_lti
    @consumer = Consumer.find_by(id: params[:consumer_id])
    @submission = Submission.find(params[:submission_id])
    clear_lti_session_data
  end

  def new
    if current_user
      flash[:warning] = t('shared.already_signed_in')
      redirect_to(:root)
    end
  end
end
