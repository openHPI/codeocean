# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit

  MEMBER_ACTIONS = %i[destroy edit show update].freeze

  after_action :verify_authorized, except: %i[welcome]
  around_action :mnemosyne_trace
  before_action :set_sentry_context, :set_locale, :allow_iframe_requests, :load_embed_options
  protect_from_forgery(with: :exception, prepend: true)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_csrf_error

  def current_user
    ::NewRelic::Agent.add_custom_attributes(external_user_id: session[:external_user_id],
session_user_id: session[:user_id])
    @current_user ||= ExternalUser.find_by(id: session[:external_user_id]) || login_from_session || login_from_other_sources || nil
  end

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

  def set_sentry_context
    return if current_user.blank?

    Sentry.set_user(
      id: current_user.id,
      type: current_user.class.name,
      username: current_user.displayname,
      consumer: current_user.consumer.name
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

  def render_error(message, status)
    set_sentry_context
    respond_to do |format|
      format.html do
        # Prevent redirect loop
        if request.url == request.referer
          redirect_to :root, alert: message
        else
          redirect_back fallback_location: :root, allow_other_host: false, alert: message
        end
      end
      format.json { render json: {error: message}, status: status }
    end
  end
  private :render_error

  def set_locale
    session[:locale] = params[:custom_locale] || params[:locale] || session[:locale]
    I18n.locale = session[:locale] || I18n.default_locale
    Sentry.set_extras(locale: I18n.locale)
  end
  private :set_locale

  def welcome
    # Show root page
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
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
end
