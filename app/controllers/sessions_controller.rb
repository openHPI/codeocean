# frozen_string_literal: true

class SessionsController < ApplicationController
  include Lti

  %i[require_oauth_parameters require_valid_consumer_key require_valid_oauth_signature require_unique_oauth_nonce
     require_valid_launch_presentation_return_url require_valid_lis_outcome_service_url set_current_user require_valid_exercise_token
     set_study_group_membership set_embedding_options].each do |method_name|
    before_action(method_name, only: :create_through_lti)
  end

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token, only: :create_through_lti
  after_action :set_sentry_context

  def new
    redirect_to(:root, alert: t('shared.already_signed_in')) if current_user
  end

  def create_through_lti
    return redirect_to_survey if params[:custom_survey_id]

    # Remove any previous pg_id and pair_programming option from the session
    session.delete(:pg_id)
    session.delete(:pair_programming)

    store_lti_session_data(params)
    store_nonce(params[:oauth_nonce])
    if params[:custom_redirect_target]
      redirect_to(URI.parse(params[:custom_redirect_target].to_s).path)
    elsif params[:custom_pair_programming]
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
      sorcery_redirect_back_or_to(:root, notice: t('.success'))
    else
      flash.now[:danger] = t('.failure')
      render(:new)
    end
  end

  def destroy_through_lti
    @submission = Submission.find(params[:submission_id])
    authorize(@submission, :show?)
    if current_user.external_user?
      @lti_parameter = current_user.lti_parameters.find_by(exercise: @submission.exercise, study_group_id: current_user.current_study_group_id)
      @url = consumer_return_url(build_tool_provider(consumer: current_user.consumer, parameters: @lti_parameter&.lti_parameters))
    end
  end

  def destroy
    if current_user&.external_user?
      session.delete(:external_user_id)
      session.delete(:study_group_id)
      session.delete(:embed_options)
      session.delete(:pg_id)
      session.delete(:pair_programming)

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

  private

  def redirect_to_survey
    if params[:custom_bonus_points]
      # The following code is taken from store_lti_session_data(params) & send_score_for(submission, user)
      # It gives a bonus point to users who opened the survey
      begin
        lti_parameters = params.slice(*Lti::SESSION_PARAMETERS).permit!.to_h
        provider = build_tool_provider(consumer: current_user.consumer, parameters: lti_parameters)
        provider.post_replace_result!(1.0)
      rescue IMS::LTI::InvalidLTIConfigError, IMS::LTI::XMLParseError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError, EOFError
        # We don't do anything here because it is only a bonus point and we want the users to do the survey
      end
    end

    # This method is taken from Xikolo and slightly adapted.
    # Forward arbitrary optional query params to LimeSurvey
    # and remove tracking and other sensitive user params.
    query_params = request
      .query_parameters
      .delete_if {|key, _| key.to_s.match(/.*(tracking|referrer|user_id).*/) }
      .merge(
        r: 'survey/index', # required LimeSurvey path passed as query param
        sid: params[:custom_survey_id], # required LimeSurvey survey ID
        newtest: 'Y', # force a new LimeSurvey session
        xi_platform: 'openhpi' # pass a platform identifier
      ).tap do |qp|
      if current_user
        # add a user pseudo ID if applicable
        qp[:xi_pseudo_id] = Digest::SHA256.hexdigest(current_user.external_id)
        qp[:co_study_group_id] = current_user.current_study_group_id
        qp[:co_rfcs] = current_user.request_for_comments.includes(:submission).where(submission: {study_group_id: current_user.current_study_group_id}).size.to_s
        qp[:co_comments] = current_user.comments.includes(:submission).where(submission: {study_group_id: current_user.current_study_group_id}).size.to_s
      end
    end

    uri = Addressable::URI.parse 'https://survey.openhpi.de/survey/index.php'
    uri.query_values = query_params

    redirect_to uri.to_s, allow_other_host: true
  end
end
