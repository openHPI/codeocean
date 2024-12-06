# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  include ApplicationHelper
  include I18nHelper
  include Pundit::Authorization
  include Webauthn::Authentication

  MEMBER_ACTIONS = %i[destroy edit show update].freeze
  RENDER_HOST = CodeOcean::Config.new(:code_ocean).read[:render_host]
  LEGAL_SETTINGS = CodeOcean::Config.new(:code_ocean).read[:legal] || {}
  MONITORING_USER_AGENT = /updown\.io/

  before_action :deny_access_from_render_host, prepend: true
  after_action :verify_authorized, except: %i[welcome]
  around_action :mnemosyne_trace, prepend: true
  around_action :switch_locale, prepend: true
  before_action :check_current_user, prepend: true
  before_action :set_sentry_context, :load_embed_options, :set_document_policy
  skip_before_action :require_fully_authenticated_user!, only: %i[welcome]
  protect_from_forgery(with: :exception, prepend: true)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_csrf_error
  add_flash_types :danger, :warning, :info, :success

  def current_user
    return @current_user if defined? @current_user

    @current_user = find_or_login_current_user&.store_current_study_group_id(session[:study_group_id])
    _store_authentication_result(@current_user)
  end

  def current_contributor
    return @current_contributor if defined? @current_contributor

    @current_contributor = if session[:pg_id]
                             current_user.programming_groups.find(session[:pg_id])
                           else
                             current_user
                           end
  end
  helper_method :current_contributor

  def welcome
    # Show root page
    redirect_to ping_index_path if MONITORING_USER_AGENT.match?(request.user_agent)
    _require_webauthn_credential_authentication if current_user&.webauthn_configured?
  end

  private

  def check_current_user
    # Simply accessing the current_user will trigger the authentication process:
    # If the user is not authenticated but a remember_me cookie is present,
    # the user might be redirected to the WebAuthn Credential Authentication page.
    # Therefore, we use `prepend: true` to ensure that this method is called before
    # the `require_fully_authenticated_user!` method.
    current_user
  end

  def deny_access_from_render_host
    raise Pundit::NotAuthorizedError if RENDER_HOST.present? && request.host == RENDER_HOST
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

  def find_or_login_current_user
    login_from_authentication_token ||
      login_from_lti_session ||
      login_from_session ||
      login_from_other_sources ||
      nil
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

      session[:return_to_url] = request.fullpath
      authenticate(token.user)
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

  def set_document_policy
    # Instruct browsers to capture profiling data
    response.set_header('Document-Policy', 'js-profiling')
  end

  def render_csrf_error
    render_error t('sessions.expired'), :unprocessable_content
  end

  def render_not_authorized
    render_error t('application.not_authorized'), :unauthorized
  end

  def render_not_found
    if current_user&.admin?
      render_error t('application.not_found'), :not_found
    else
      render_not_authorized
    end
  end

  def render_error(message, status)
    set_sentry_context
    respond_to do |format|
      format.any do
        # Prevent redirect loop
        if request.url == request.referer || request.referer&.match?(sign_in_path)
          redirect_to :root, alert: message
        # Redirect to main domain if the request originated from our render_host
        elsif request.path == '/' && request.host == RENDER_HOST
          redirect_to Rails.application.config.action_mailer.default_url_options, allow_other_host: true
        elsif current_user.nil? && status == :unauthorized
          session[:return_to_url] = request.fullpath if current_user.nil?
          redirect_to sign_in_path, alert: t('application.not_signed_in')
        else
          redirect_back fallback_location: :root, allow_other_host: false, alert: message
        end
      end
      format.json { render json: {error: message}, status: }
    end
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

  def set_content_type_nosniff
    # When sending a file, we want to ensure that browsers follow our Content-Type header
    response.headers['X-Content-Type-Options'] = 'nosniff'
  end
end
