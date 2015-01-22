class InternalUsersController < ApplicationController
  before_action :require_activation_token, only: :activate
  before_action :require_reset_password_token, only: :reset_password
  before_action :set_user, only: MEMBER_ACTIONS
  skip_before_action :verify_authenticity_token, only: :activate
  skip_after_action :verify_authorized, only: [:activate, :forgot_password, :reset_password]

  def activate
    if request.patch? || request.put?
      respond_to do |format|
        if @user.update(params[:internal_user].permit(:password, :password_confirmation))
          @user.activate!
          format.html { redirect_to(sign_in_path, notice: t('.success')) }
          format.json { render(nothing: true, status: :ok) }
        else
          format.html { render(:activate) }
          format.json { render(json: @user.errors, status: :unprocessable_entity) }
        end
      end
    end
  end

  def authorize!
    authorize(@user || @users)
  end
  private :authorize!

  def create
    @user = InternalUser.new(internal_user_params)
    authorize!
    @user.send(:setup_activation)
    respond_to do |format|
      if @user.save
        @user.send(:send_activation_needed_email!)
        format.html { redirect_to(@user, notice: t('shared.object_created', model: InternalUser.model_name.human)) }
        format.json { render(:show, location: @user, status: :created) }
      else
        format.html { render(:new) }
        format.json { render(json: @user.errors, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to(internal_users_url, notice: t('shared.object_destroyed', model: InternalUser.model_name.human)) }
      format.json { head(:no_content) }
    end
  end

  def edit
  end

  def forgot_password
    if request.get? && current_user
      flash[:warning] = t('shared.already_signed_in')
      redirect_to(:root)
    elsif request.post?
      if params[:email].present?
        InternalUser.find_by(email: params[:email]).try(:deliver_reset_password_instructions!)
        flash[:notice] = t('.success')
        redirect_to(:root)
      end
    end
  end

  def index
    @search = InternalUser.search(params[:q])
    @users = @search.result.order(:name)
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

  def require_activation_token
    @user = InternalUser.load_from_activation_token(params[:token] || params[:internal_user].try(:[], :activation_token))
    render_not_authorized unless @user
  end
  private :require_activation_token

  def require_reset_password_token
    @user = InternalUser.load_from_reset_password_token(params[:token] || params[:internal_user].try(:[], :reset_password_token))
    render_not_authorized unless @user
  end
  private :require_reset_password_token

  def reset_password
    if request.patch? || request.put?
      respond_to do |format|
        if @user.update(params[:internal_user].permit(:password, :password_confirmation))
          @user.change_password!(params[:internal_user][:password])
          format.html { redirect_to(sign_in_path, notice: t('.success')) }
          format.json { render(nothing: true, status: :ok) }
        else
          format.html { render(:reset_password) }
          format.json { render(json: @user.errors, status: :unprocessable_entity) }
        end
      end
    end
  end

  def set_user
    @user = InternalUser.find(params[:id])
    authorize!
  end
  private :set_user

  def show
  end

  def update
    respond_to do |format|
      if @user.update(internal_user_params)
        format.html { redirect_to(@user, notice: t('shared.object_updated', model: InternalUser.model_name.human)) }
        format.json { render(:show, location: @user, status: :ok) }
      else
        format.html { render(:edit) }
        format.json { render(json: @user.errors, status: :unprocessable_entity) }
      end
    end
  end
end
