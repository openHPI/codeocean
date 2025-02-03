# frozen_string_literal: true

class InternalUsersController < ApplicationController
  include CommonBehavior

  before_action :require_activation_token, only: :activate
  before_action :require_reset_password_token, only: :reset_password
  before_action :set_user, only: MEMBER_ACTIONS + %i[change_password]
  before_action :collect_set_and_unset_study_group_memberships, only: MEMBER_ACTIONS + %i[create]
  skip_before_action :require_fully_authenticated_user!, only: %i[activate forgot_password reset_password]
  skip_after_action :verify_authorized, only: %i[activate forgot_password reset_password]

  def activate
    set_up_password if request.patch? || request.put?
  end

  def index
    @search = policy_scope(InternalUser).ransack(params[:q], {auth_object: current_user})
    @users = @search.result.includes(:consumer).order(:name).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def new
    @user = InternalUser.new
    authorize!
    collect_set_and_unset_study_group_memberships
  end

  def forgot_password
    if request.get?
      render_forgot_password_form
    elsif request.post?
      deliver_reset_password_instructions
    end
  end

  def edit; end

  def create
    platform_admin = platform_admin_param
    @user = InternalUser.new(internal_user_params)
    @user.platform_admin = platform_admin if current_user.admin?
    authorize!
    @user.send(:setup_activation)
    create_and_respond(object: @user) do
      @user.send(:send_activation_needed_email!)
      # The return value is used as a flash message. If this block does not
      # have any specific return value, a default success message is shown.
      nil
    end
  end

  def reset_password
    change_password if request.patch? || request.put?
  end

  def update
    # Let's skip the password validation if the user is edited through
    # the form here. Otherwise, the update might fail if an
    # activation_token or password_reset_token is present
    @user.validate_password = false
    @user.platform_admin = platform_admin_param if current_user.admin?
    update_and_respond(object: @user, params: internal_user_params)
  end

  def change_password
    return render :change_password unless request.patch? || request.put?

    if @user != current_user || @user.valid_password?(params[:internal_user].delete(:current_password))
      # Always validate the password strength when changing the password
      @user.validate_password = true
      update_password
    else
      respond_to do |format|
        @user.errors.add(:base, :current_password_invalid)
        respond_with_invalid_object(format, object: @user, template: :change_password)
      end
    end
  end

  def destroy
    destroy_and_respond(object: @user)
  end

  private

  def authorize!
    authorize(@user || @users)
  end

  def update_password
    respond_to do |format|
      if @user.update(params[:internal_user].permit(:password, :password_confirmation))
        @user.change_password!(params[:internal_user][:password])
        redirect_target = current_user ? internal_user_path(@user) : sign_in_path
        format.html { redirect_to(redirect_target, notice: t('internal_users.reset_password.success')) }
        format.json { head :ok }
      else
        respond_with_invalid_object(format, object: @user, template: action_name.to_sym)
      end
    end
  end

  def deliver_reset_password_instructions
    if params[:email].present?
      user = InternalUser.arel_table
      InternalUser.where(user[:email].matches(params[:email])).first&.deliver_reset_password_instructions!
      redirect_to(:root, notice: t('internal_users.forgot_password.success'))
    end
  end

  def internal_user_params
    permitted_params = params.expect(internal_user: [:consumer_id, :email, :name, {study_group_ids: []}]).presence || {}
    checked_study_group_memberships = @study_group_memberships.select {|sgm| permitted_params[:study_group_ids]&.include? sgm.study_group.id.to_s }
    removed_study_group_memberships = @study_group_memberships.reject {|sgm| permitted_params[:study_group_ids]&.include? sgm.study_group.id.to_s }

    checked_study_group_memberships.each do |sgm|
      sgm.role = params[:study_group_membership_roles][sgm.study_group.id.to_s][:role]
      sgm.user = @user
    end

    permitted_params[:study_group_memberships] = checked_study_group_memberships
    permitted_params.delete :study_group_ids
    removed_study_group_memberships.map(&:destroy)
    permitted_params
  end

  def platform_admin_param
    params.require(:internal_user).delete(:platform_admin)
  end

  def render_forgot_password_form
    redirect_to(:root, alert: t('shared.already_signed_in')) if current_user
  end

  def require_activation_token
    require_token(:activation)
  end

  def require_reset_password_token
    require_token(:reset_password)
  end

  def require_token(type)
    token = params.delete(:token) # Used when a user clicks on a link in an email
    token ||= params[:internal_user]&.delete(:"#{type}_token") # Used when a user sets / changes the password and submit the form
    @user = InternalUser.send(:"load_from_#{type}_token", token)
    render_not_authorized unless @user
  end

  def set_up_password
    respond_to do |format|
      if @user.update(params[:internal_user].permit(:password, :password_confirmation))
        @user.activate!
        format.html { redirect_to(sign_in_path, notice: t('internal_users.activate.success')) }
        format.json { head :ok }
      else
        respond_with_invalid_object(format, object: @user, template: :activate)
      end
    end
  end

  def set_user
    @user = InternalUser.find(params[:id])
    authorize!
  end

  def collect_set_and_unset_study_group_memberships
    @study_groups = policy_scope(StudyGroup)
    @user ||= InternalUser.new # Only needed for the `create` action
    checked_study_group_memberships = @user.study_group_memberships
    checked_study_groups = checked_study_group_memberships.collect(&:study_group).sort.to_set
    unchecked_study_groups = StudyGroup.order(name: :asc).to_set.subtract checked_study_groups
    @study_group_memberships = checked_study_group_memberships + unchecked_study_groups.collect do |study_group|
      StudyGroupMembership.new(user: @user, study_group:)
    end
  end
end
