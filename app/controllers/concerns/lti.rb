require 'oauth/request_proxy/rack_request'

module Lti
  extend ActiveSupport::Concern

  MAXIMUM_SCORE = 1
  MAXIMUM_SESSION_AGE = 60.minutes
  SESSION_PARAMETERS = %w(launch_presentation_return_url lis_outcome_service_url lis_result_sourcedid)

  def build_tool_provider(options = {})
    if options[:consumer] && options[:parameters]
      IMS::LTI::ToolProvider.new(options[:consumer].oauth_key, options[:consumer].oauth_secret, options[:parameters])
    end
  end
  private :build_tool_provider

  def clear_lti_session_data
    session.delete(:consumer_id)
    session.delete(:external_user_id)
    session.delete(:lti_parameters)
  end
  private :clear_lti_session_data

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
    if provider.lis_person_name_full
      provider.lis_person_name_full
    elsif provider.lis_person_name_given && provider.lis_person_name_family
      "#{provider.lis_person_name_given} #{provider.lis_person_name_family}"
    else
      provider.lis_person_name_given || provider.lis_person_name_family
    end
  end
  private :external_user_name

  def lti_outcome_service?
    session[:lti_parameters].try(:has_key?, 'lis_outcome_service_url')
  end
  private :lti_outcome_service?

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
    @exercise = Exercise.find_by(token: params[:custom_token])
    refuse_lti_launch(message: t('sessions.oauth.invalid_exercise_token')) unless @exercise
  end
  private :require_valid_exercise_token

  def require_valid_oauth_signature
    @provider = build_tool_provider(consumer: @consumer, parameters: params)
    refuse_lti_launch(message: t('sessions.oauth.invalid_signature')) unless @provider.valid_request?(request)
  end
  private :require_valid_oauth_signature

  def return_to_consumer(options = {})
    consumer_return_url = @provider.try(:launch_presentation_return_url) || params[:launch_presentation_return_url]
    if consumer_return_url
      consumer_return_url += "?#{options.to_query}" if options.present?
      redirect_to(consumer_return_url)
    else
      flash[:danger] = options[:lti_errormsg]
      flash[:info] = options[:lti_msg]
      redirect_to(:root)
    end
  end
  private :return_to_consumer

  def send_score(score)
    ::NewRelic::Agent.add_custom_parameters({ score: score, session: session })
    fail(Error, "Score #{score} must be between 0 and #{MAXIMUM_SCORE}!") unless (0..MAXIMUM_SCORE).include?(score)
    provider = build_tool_provider(consumer: Consumer.find_by(id: session[:consumer_id]), parameters: session[:lti_parameters])
    if provider.nil?
      {status: 'error'}
    elsif provider.outcome_service?
      response = provider.post_replace_result!(score)
      {code: response.response_code, message: response.post_response.body, status: response.code_major}
    else
      {status: 'unsupported'}
    end
  end
  private :send_score

  def set_current_user
    @current_user = ExternalUser.find_or_create_by(consumer_id: @consumer.id, external_id: @provider.user_id)
    @current_user.update(email: external_user_email(@provider), name: external_user_name(@provider))
  end
  private :set_current_user

  def store_lti_session_data(options = {})
    session[:consumer_id] = options[:consumer].id
    session[:external_user_id] = @current_user.id
    session[:lti_parameters] = options[:parameters].slice(*SESSION_PARAMETERS)
  end
  private :store_lti_session_data

  def store_nonce(nonce)
    NonceStore.add(nonce)
  end
  private :store_nonce

  class Error < RuntimeError
  end
end
