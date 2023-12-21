# frozen_string_literal: true

class StudyGroupsController < ApplicationController
  include CommonBehavior

  before_action :set_group, only: MEMBER_ACTIONS + %w[set_as_current]

  def index
    @search = policy_scope(StudyGroup).ransack(params[:q])
    @study_groups_paginate = @search.result.includes(:consumer).order(:name).paginate(page: params[:page], per_page: per_page_param)
    @study_groups = @study_groups_paginate.joins(:study_group_memberships)
      .group(:id, :name, :external_id, :consumer_id, :created_at, :updated_at)
      .select(:id, :name, :external_id, :consumer_id, :created_at, :updated_at, 'count(study_group_memberships.id) as user_count')
    authorize!
  end

  def show; end

  def edit
    @members = @study_group.study_group_memberships.includes(:user)
  end

  def update
    myparams = study_group_params
    @members = @study_group.study_group_memberships.includes(:user)
    myparams[:external_users] = @members.where(id: myparams[:study_group_membership_ids].compact_blank).map(&:user)
    update_and_respond(object: @study_group, params: myparams)
  end

  def destroy
    destroy_and_respond(object: @study_group)
  end

  def study_group_params
    params.require(:study_group).permit(:name, study_group_membership_ids: [])
  end
  private :study_group_params

  def set_as_current
    session[:study_group_id] = @study_group.id
    current_user.store_current_study_group_id(@study_group.id)
    redirect_back_or_to(root_path, notice: t('study_groups.set_as_current.success'))
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
