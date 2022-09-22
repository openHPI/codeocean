# frozen_string_literal: true

class StudyGroupsController < ApplicationController
  include CommonBehavior

  before_action :set_group, only: MEMBER_ACTIONS + %w[set_as_current]

  def index
    @search = policy_scope(StudyGroup).ransack(params[:q])
    @study_groups = @search.result.includes(:consumer).order(:name).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def edit
    @members = StudyGroupMembership.where(user: @study_group.users, study_group: @study_group).includes(:user)
  end

  def update
    myparams = study_group_params
    myparams[:external_users] =
      StudyGroupMembership.find(myparams[:study_group_membership_ids].compact_blank).map(&:user)
    myparams.delete(:study_group_membership_ids)
    update_and_respond(object: @study_group, params: myparams)
  end

  def destroy
    destroy_and_respond(object: @study_group)
  end

  def study_group_params
    params[:study_group].permit(:id, :name, study_group_membership_ids: []) if params[:study_group].present?
  end
  private :study_group_params

  def set_as_current
    session[:study_group_id] = @study_group.id
    current_user.store_current_study_group_id(@study_group.id)
    redirect_back(fallback_location: root_path, notice: t('study_groups.set_as_current.success'))
  end

  def set_group
    @study_group = StudyGroup.find(params[:id])
    authorize!
  end
  private :set_group

  def authorize!
    authorize(@study_groups || @study_group)
  end
  private :authorize!
end
