# frozen_string_literal: true

class StudyGroupsController < ApplicationController
  include CommonBehavior

  before_action :set_group, only: MEMBER_ACTIONS

  def index
    @search = policy_scope(StudyGroup).ransack(params[:q])
    @study_groups = @search.result.includes(:consumer).order(:name).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show
    @search = @study_group.external_users.ransack(params[:q])
  end

  def edit
    @search = @study_group.external_users.ransack(params[:q])
    @members = StudyGroupMembership.where(user: @search.result, study_group: @study_group)
  end

  def update
    myparams = study_group_params
    myparams[:external_users] =
      StudyGroupMembership.find_by(id: myparams[:study_group_membership_ids].compact_blank).map(&:user)
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

  def set_group
    @study_group = StudyGroup.find_by(id: params[:id])
    authorize!
  end
  private :set_group

  def authorize!
    authorize(@study_groups || @study_group)
  end
  private :authorize!
end
