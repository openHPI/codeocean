class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit

  MEMBER_ACTIONS = [:destroy, :edit, :show, :update]

  after_action :verify_authorized, except: [:help, :welcome]
  before_action :set_locale, :allow_iframe_requests
  protect_from_forgery(with: :exception)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized

  def current_user
    ::NewRelic::Agent.add_custom_attributes({ external_user_id: session[:external_user_id], session_user_id: session[:user_id] })
    @current_user ||= ExternalUser.find_by(id: session[:external_user_id]) || login_from_session || login_from_other_sources
  end

  def help
  end

  def render_not_authorized
    redirect_to(:root, alert: t('application.not_authorized'))
  end
  private :render_not_authorized

  def set_locale
    session[:locale] = params[:custom_locale] || params[:locale] || session[:locale]
    I18n.locale = session[:locale] || I18n.default_locale
  end
  private :set_locale

  def welcome
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end
