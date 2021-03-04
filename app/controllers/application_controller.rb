# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit

  MEMBER_ACTIONS = %i[destroy edit show update].freeze

  after_action :verify_authorized, except: %i[help welcome]
  before_action :set_sentry_context, :set_locale, :allow_iframe_requests, :load_embed_options
  protect_from_forgery(with: :exception, prepend: true)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized

  def current_user
    ::NewRelic::Agent.add_custom_attributes(external_user_id: session[:external_user_id], session_user_id: session[:user_id])
    @current_user ||= ExternalUser.find_by(id: session[:external_user_id]) || login_from_session || login_from_other_sources || nil
  end

  def require_user!
    raise Pundit::NotAuthorizedError unless current_user
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

  def render_not_authorized
    respond_to do |format|
      format.html do
        # Prevent redirect loop
        if request.url == request.referrer
          redirect_to :root, alert: t('application.not_authorized')
        else
          redirect_back fallback_location: :root, allow_other_host: false, alert: t('application.not_authorized')
        end
      end
      format.json { render json: {error: t('application.not_authorized')}, status: :unauthorized }
    end
  end
  private :render_not_authorized

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
