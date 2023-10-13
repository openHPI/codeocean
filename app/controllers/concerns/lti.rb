# frozen_string_literal: true

require 'oauth/request_proxy/action_controller_request'

module Lti
  extend ActiveSupport::Concern
  include LtiHelper

  MAXIMUM_SCORE = 1
  MAXIMUM_SESSION_AGE = 60.minutes
  SESSION_PARAMETERS = %w[launch_presentation_return_url lis_outcome_service_url lis_result_sourcedid].freeze
  ERROR_STATUS = %w[error unsupported].freeze

  def build_tool_provider(options = {})
    if options[:consumer] && options[:parameters]
      IMS::LTI::ToolProvider.new(options[:consumer].oauth_key, options[:consumer].oauth_secret, options[:parameters])
    end
  end

  private :build_tool_provider

  def consumer_return_url(provider, options = {})
    consumer_return_url = provider.try(:launch_presentation_return_url) || params[:launch_presentation_return_url]
    consumer_return_url += "?#{options.to_query}" if consumer_return_url && options.present?
    consumer_return_url
  end

  def external_user_email(provider)
    provider.lis_person_contact_email_primary
  end

  private :external_user_email

  def external_user_name(provider)
    # save person_name_full if supplied. this is the display_name, if it is set.
    # else only save the firstname, we don't want lastnames (family names)
    provider.lis_person_name_full || provider.lis_person_name_given
  end

  private :external_user_name

  def external_user_role(provider)
    result = 'learner'
    if provider.roles.present?
      provider.roles.each do |role|
        case role.downcase
          when 'administrator', 'instructor'
            # We don't want anyone to get admin privileges through LTI
            result = 'teacher' if result == 'learner'
          else # 'learner'
            next
        end
      end
    end
    result
  end

  def context_id?
    # All platforms (except HPI Schul-Cloud) set the context_id
    params[:context_id]
  end

  def refuse_lti_launch(options = {})
    return_to_consumer(lti_errorlog: options[:message], lti_errormsg: t('sessions.oauth.failure'))
  end

  private :refuse_lti_launch

  def require_oauth_parameters
    refuse_lti_launch(message: t('sessions.oauth.missing_parameters')) unless params[:oauth_consumer_key] && params[:oauth_signature]
  end

  private :require_oauth_parameters

  def require_unique_oauth_nonce
    refuse_lti_launch(message: t('sessions.oauth.used_nonce')) if NonceStore.has?(params[:oauth_nonce])
  end

  private :require_unique_oauth_nonce

  def require_valid_consumer_key
    @consumer = Consumer.find_by(oauth_key: params[:oauth_consumer_key])
    refuse_lti_launch(message: t('sessions.oauth.invalid_consumer')) unless @consumer
  end

  private :require_valid_consumer_key

  def require_valid_exercise_token
    proxy_exercise = ProxyExercise.find_by(token: params[:custom_token])
    @exercise = if proxy_exercise.nil?
                  Exercise.find_by(token: params[:custom_token])
                else
                  proxy_exercise.get_matching_exercise(current_user)
                end
    refuse_lti_launch(message: t('sessions.oauth.invalid_exercise_token')) unless @exercise
  end

  private :require_valid_exercise_token

  def require_valid_oauth_signature
    @provider = build_tool_provider(consumer: @consumer, parameters: params)
    refuse_lti_launch(message: t('sessions.oauth.invalid_signature')) unless @provider.valid_request?(request)
  end

  private :require_valid_oauth_signature

  def return_to_consumer(options = {})
    consumer_return_url = @provider.try(:launch_presentation_return_url)
    if consumer_return_url
      consumer_return_url += "?#{options.to_query}" if options.present?
      redirect_to(consumer_return_url, allow_other_host: true)
    else
      flash[:danger] = options[:lti_errormsg]
      flash[:info] = options[:lti_msg]
      redirect_to(:root)
    end
  end

  private :return_to_consumer

  def send_scores(submission)
    unless (0..MAXIMUM_SCORE).cover?(submission.normalized_score)
      raise Error.new("Score #{submission.normalized_score} must be between 0 and #{MAXIMUM_SCORE}!")
    end

    submission.users.map {|user| send_score_for submission, user }
  end

  private :send_scores

  def send_score_for(submission, user)
    if user.external_user? && user.consumer
      lti_parameter = user.lti_parameters.find_by(exercise: submission.exercise, study_group: submission.study_group)
      provider = build_tool_provider(consumer: user.consumer, parameters: lti_parameter&.lti_parameters)
    end

    if provider.nil?
      {status: 'error', user: user.displayname}
    elsif provider.outcome_service?
      Sentry.set_extras({
        provider: provider.inspect,
        score: submission.normalized_score,
        lti_parameter: lti_parameter.inspect,
        session: session.to_hash,
        exercise_id: submission.exercise_id,
      })
      normalized_lti_score = submission.normalized_score
      if submission.before_deadline?
        # Keep the full score
      elsif submission.within_grace_period?
        # Reduce score by 20%
        normalized_lti_score *= 0.8
      elsif submission.after_late_deadline?
        # Reduce score by 100%
        normalized_lti_score *= 0.0
      end

      begin
        response = provider.post_replace_result!(normalized_lti_score)
        {code: response.response_code, message: response.post_response.body, status: response.code_major, score_sent: normalized_lti_score, user: user.displayname}
      rescue IMS::LTI::XMLParseError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, SocketError, EOFError
        # A parsing error might happen if the LTI provider is down and doesn't return a valid XML response
        {status: 'error', user: user.displayname}
      end
    else
      {status: 'unsupported', user: user.displayname}
    end
  end

  private :send_score_for

  def set_current_user
    @current_user = ExternalUser.find_or_create_by(consumer_id: @consumer.id, external_id: @provider.user_id)
    current_user.update(email: external_user_email(@provider), name: external_user_name(@provider))
  end

  private :set_current_user

  def set_study_group_membership
    group = if context_id?
              # Ensure to find the group independent of the name and set it only once.
              StudyGroup.find_or_create_by(external_id: @provider.context_id, consumer: @consumer) do |new_group|
                new_group.name = @provider.context_title
              end
            else
              StudyGroup.find_or_create_by(external_id: @provider.resource_link_id, consumer: @consumer)
            end

    study_group_membership = StudyGroupMembership.find_or_create_by(study_group: group, user: current_user)
    study_group_membership.update(role: external_user_role(@provider))
    session[:study_group_id] = group.id
    current_user.store_current_study_group_id(group.id)
  end

  def set_embedding_options
    @embed_options = {}
    %i[hide_navbar
       hide_exercise_description
       collapse_exercise_description
       disable_run
       disable_score
       disable_rfc
       disable_redirect_to_rfcs
       disable_redirect_to_feedback
       disable_interventions
       hide_sidebar
       read_only
       hide_test_results
       disable_hints
       disable_download].each do |option|
      value = params["custom_embed_options_#{option}".to_sym] == 'true'
      # Optimize storage and save only those that are true, the session cookie is limited to 4KB
      @embed_options[option] = value if value.present?
    end
    session[:embed_options] = @embed_options
  end

  private :set_embedding_options

  def store_lti_session_data(parameters)
    @lti_parameters = LtiParameter.find_or_initialize_by(external_user: current_user,
      study_group_id: session[:study_group_id],
      exercise: @exercise)

    @lti_parameters.lti_parameters = parameters.slice(*SESSION_PARAMETERS).permit!.to_h
    @lti_parameters.save!

    session[:external_user_id] = current_user.id
    session[:pair_programming] = parameters[:custom_pair_programming] || false
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    retry
  end

  private :store_lti_session_data

  def store_nonce(nonce)
    NonceStore.add(nonce)
  end

  private :store_nonce

  class Error < RuntimeError
  end
end
