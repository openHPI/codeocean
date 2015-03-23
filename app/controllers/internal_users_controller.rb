class InternalUsersController < ApplicationController
  include CommonBehavior

  before_action :require_activation_token, only: :activate
  before_action :require_reset_password_token, only: :reset_password
  before_action :set_user, only: MEMBER_ACTIONS
  skip_before_action :verify_authenticity_token, only: :activate
  skip_after_action :verify_authorized, only: [:activate, :forgot_password, :reset_password]

  def activate
    set_up_password if request.patch? || request.put?
  end

  def authorize!
    authorize(@user || @users)
  end
  private :authorize!

  def change_password
    respond_to do |format|
      if @user.update(params[:internal_user].permit(:password, :password_confirmation))
        @user.change_password!(params[:internal_user][:password])
        format.html { redirect_to(sign_in_path, notice: t('.success')) }
        format.json { render(nothing: true, status: :ok) }
      else
        respond_with_invalid_object(format, object: @user, template: :reset_password)
      end
    end
  end
  private :change_password

  def create
    @user = InternalUser.new(internal_user_params)
    authorize!
    @user.send(:setup_activation)
    create_and_respond(object: @user) { @user.send(:send_activation_needed_email!) }
  end

  def deliver_reset_password_instructions
    if params[:email].present?
      InternalUser.find_by(email: params[:email]).try(:deliver_reset_password_instructions!)
      redirect_to(:root, notice: t('.success'))
    end
  end
  private :deliver_reset_password_instructions

  def destroy
    destroy_and_respond(object: @user)
  end

  def edit
  end

  def forgot_password
    if request.get?
      render_forgot_password_form
    elsif request.post?
      deliver_reset_password_instructions
    end
  end

  def index
    @search = InternalUser.search(params[:q])
    @users = @search.result.includes(:consumer).order(:name).paginate(page: params[:page])
    authorize!
  end

  def internal_user_params
    params[:internal_user].permit(:consumer_id, :email, :name, :role)
  end
  private :internal_user_params

  def new
    @user = InternalUser.new
    authorize!
  end

  def render_forgot_password_form
    redirect_to(:root, alert: t('shared.already_signed_in')) if current_user
  end
  private :render_forgot_password_form

  def require_activation_token
    require_token(:activation)
  end
  private :require_activation_token

  def require_reset_password_token
    require_token(:reset_password)
  end
  private :require_reset_password_token

  def require_token(type)
    @user = InternalUser.send(:"load_from_#{type}_token", params[:token] || params[:internal_user].try(:[], :"#{type}_token"))
    render_not_authorized unless @user
  end
  private :require_token

  def reset_password
    change_password if request.patch? || request.put?
  end

  def set_up_password
    respond_to do |format|
      if @user.update(params[:internal_user].permit(:password, :password_confirmation))
        @user.activate!
        format.html { redirect_to(sign_in_path, notice: t('.success')) }
        format.json { render(nothing: true, status: :ok) }
      else
        respond_with_invalid_object(format, object: @user, template: :activate)
      end
    end
  end
  private :set_up_password

  def set_user
    @user = InternalUser.find(params[:id])
    authorize!
  end
  private :set_user

  def show
  end

  def update
    update_and_respond(object: @user, params: internal_user_params)
  end
end
