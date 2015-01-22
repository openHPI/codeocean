class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit

  MEMBER_ACTIONS = [:destroy, :edit, :show, :update]

  after_action :verify_authorized, except: [:help, :welcome]
  before_action :set_locale
  protect_from_forgery(with: :exception)
  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized

  def current_user
    @current_user ||= ExternalUser.find_by(id: session[:external_user_id]) || login_from_session || login_from_other_sources
  end

  def help
  end

  def render_not_authorized
    flash[:danger] = t('application.not_authorized')
    redirect_to(:root)
  end
  private :render_not_authorized

  def set_locale
    session[:locale] = params[:locale] if params[:locale]
    I18n.locale = session[:locale] || I18n.default_locale
  end
  private :set_locale

  def welcome
  end
end
