# frozen_string_literal: true

class ProgrammingGroupsController < ApplicationController
  include CommonBehavior
  include LtiHelper

  before_action :set_exercise_and_authorize

  def new
    @programming_group = ProgrammingGroup.new(exercise: @exercise)
    authorize!
    existing_programming_group = current_user.programming_groups.find_by(exercise: @exercise)
    if existing_programming_group
      session[:pg_id] = existing_programming_group.id
      redirect_to(implement_exercise_path(@exercise),
        notice: t("sessions.create_through_lti.session_#{lti_outcome_service?(@exercise, current_user) ? 'with' : 'without'}_outcome", consumer: @consumer))
    end
  end

  def create
    programming_partner_ids = programming_group_params[:programming_partner_ids].split(',').map(&:strip).uniq
    users = programming_partner_ids.map do |partner_id|
      User.find_by_id_with_type(partner_id)
    rescue ActiveRecord::RecordNotFound
      partner_id
    end
    @programming_group = ProgrammingGroup.new(exercise: @exercise, users:)
    authorize!

    unless programming_partner_ids.include? current_user.id_with_type
      @programming_group.add(current_user)
    end

    create_and_respond(object: @programming_group, path: proc { implement_exercise_path(@exercise) }) do
      session[:pg_id] = @programming_group.id
      nil
    end
  end

  private

  def authorize!
    authorize(@programming_group || @programming_groups)
  end

  def programming_group_params
    params.require(:programming_group).permit(:programming_partner_ids)
  end

  def set_exercise_and_authorize
    @exercise = Exercise.find(params[:exercise_id])
    authorize(@exercise, :implement?)
  end
end
