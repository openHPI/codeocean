# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit::Authorization

  MEMBER_ACTIONS = %i[destroy edit show update].freeze
  RENDER_HOST = CodeOcean::Config.new(:code_ocean).read[:render_host]
  LEGAL_SETTINGS = CodeOcean::Config.new(:code_ocean).read[:legal] || {}
  MONITORING_USER_AGENT = Regexp.compile(/updown\.io/).freeze

  before_action :deny_access_from_render_host
  after_action :verify_authorized, except: %i[welcome]
  around_action :mnemosyne_trace
  around_action :switch_locale
  before_action :set_sentry_context, :load_embed_options
  protect_from_forgery(with: :exception, prepend: true)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_csrf_error

  def current_user
    @current_user ||= find_or_login_current_user&.store_current_study_group_id(session[:study_group_id])
  end

  def find_or_login_current_user
    login_from_authentication_token ||
      login_from_lti_session ||
      login_from_session ||
      login_from_other_sources ||
      nil
  end
  private :find_or_login_current_user

  def require_user!
    raise Pundit::NotAuthorizedError unless current_user
  end

  def mnemosyne_trace
    yield
  ensure
    if ::Mnemosyne::Instrumenter.current_trace.present?
      ::Mnemosyne::Instrumenter.current_trace.meta['session_id'] = session[:session_id]
      ::Mnemosyne::Instrumenter.current_trace.meta['csrf_token'] = session[:_csrf_token]
      ::Mnemosyne::Instrumenter.current_trace.meta['external_user_id'] = session[:external_user_id]
    end
  end

  def login_from_lti_session
    return unless session[:external_user_id]

    ExternalUser.find_by(id: session[:external_user_id])
  end

  def login_from_authentication_token
    return unless params[:token]

    token = AuthenticationToken.find_by(shared_secret: params[:token])
    return unless token

    if token.expire_at.future?
      token.update(expire_at: Time.zone.now)
      session[:study_group_id] = token.study_group_id

      # Sorcery Login only works for InternalUsers
      return auto_login(token.user) if token.user.is_a? InternalUser

      # All external users are logged in "manually"
      session[:external_user_id] = token.user.id
      session.delete(:lti_parameters_id)
      token.user
    end
  end

  def set_sentry_context
    return if current_user.blank?

    Sentry.set_user(
      id: current_user.id,
      type: current_user.class.name,
      consumer: current_user.consumer&.name
    )
  end
  private :set_sentry_context

  def render_csrf_error
    render_error t('sessions.expired'), :unprocessable_entity
  end
  private :render_csrf_error

  def render_not_authorized
    render_error t('application.not_authorized'), :unauthorized
  end
  private :render_not_authorized

  def render_not_found
    if current_user&.admin?
      render_error t('application.not_found'), :not_found
    else
      render_not_authorized
    end
  end
  private :render_not_authorized

  def render_error(message, status)
    set_sentry_context
    respond_to do |format|
      format.any do
        # Prevent redirect loop
        if request.url == request.referer
          redirect_to :root, alert: message
        # Redirect to main domain if the request originated from our render_host
        elsif request.path == '/' && request.host == RENDER_HOST
          redirect_to Rails.application.config.action_mailer.default_url_options, allow_other_host: true
        else
          redirect_back fallback_location: :root, allow_other_host: false, alert: message
        end
      end
      format.json { render json: {error: message}, status: }
    end
  end
  private :render_error

  def switch_locale(&)
    session[:locale] = sanitize_locale(params[:custom_locale] || params[:locale] || session[:locale])
    locale = session[:locale] || http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
    Sentry.set_extras(locale:)
    I18n.with_locale(locale, &)
  end
  private :switch_locale

  def deny_access_from_render_host
    raise Pundit::NotAuthorizedError if RENDER_HOST.present? && request.host == RENDER_HOST
  end

  def welcome
    # Show root page
    redirect_to ping_index_path if MONITORING_USER_AGENT.match?(request.user_agent)
  end

  def load_embed_options
    @embed_options = if session[:embed_options].present? && session[:embed_options].is_a?(Hash)
                       session[:embed_options].symbolize_keys
                     else
                       {}
                     end
    Sentry.set_extras(@embed_options)
    @embed_options
  end
  private :load_embed_options

  # Sanitize given locale.
  #
  # Return `nil` if the locale is blank or not available.
  #
  def sanitize_locale(locale)
    return if locale.blank?

    locale = locale.downcase.to_sym
    return unless I18n.available_locales.include?(locale)

    locale
  end
  private :sanitize_locale
end
