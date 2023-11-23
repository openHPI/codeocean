# frozen_string_literal: true

class ProgrammingGroupsController < ApplicationController
  include CommonBehavior
  include LtiHelper

  before_action :set_exercise_and_authorize, only: %i[new create]
  before_action :set_programming_group_and_authorize, only: MEMBER_ACTIONS

  def index
    set_exercise_and_authorize if params[:exercise_id].present?
    @search = ProgrammingGroup.ransack(params[:q], {auth_object: current_user})
    @programming_groups = @search.result.includes(:exercise, :programming_group_memberships, :internal_users, :external_users).order(:id).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def new
    Event.create(category: 'page_visit', user: current_user, exercise: @exercise, data: 'programming_groups_new', file_id: nil)
    if current_user.submissions.where(exercise: @exercise, study_group_id: current_user.current_study_group_id).any?
      # A learner has worked on this exercise **alone** in the context of the **current study group**, so we redirect them to their progress.
      redirect_to_exercise
    elsif (existing_programming_group = current_user.programming_groups.find_by(exercise: @exercise))
      # A learner has worked on this exercise **as part of a programming group**, so we redirect them to their progress.
      session[:pg_id] = existing_programming_group.id
      redirect_to_exercise
    else
      # The learner has neither worked on this exercise alone in the context of the current study group
      # nor as part of a programming group (overall), so we allow creating a new programming group.
      @programming_group = ProgrammingGroup.new(exercise: @exercise)
      authorize!
    end
  end

  def edit
    @members = @programming_group.programming_group_memberships.includes(:user)
  end

  def create
    programming_partner_ids = programming_group_params&.fetch(:programming_partner_ids, [])&.split(',')&.map(&:strip)&.uniq
    users = programming_partner_ids&.map do |partner_id|
      User.find_by_id_with_type(partner_id)
    rescue ActiveRecord::RecordNotFound
      partner_id
    end
    @programming_group = ProgrammingGroup.new(exercise: @exercise, users:)
    authorize!

    unless programming_partner_ids&.include? current_user.id_with_type
      @programming_group.add(current_user)
    end

    unless @programming_group.valid?
      Event.create(category: 'pp_invalid_partners', user: current_user, exercise: @exercise, data: programming_group_params&.fetch(:programming_partner_ids), file_id: nil)
    end

    create_and_respond(object: @programming_group, path: proc { implement_exercise_path(@exercise) }) do
      # Inform all other users in the programming group that they have been invited.
      @programming_group.users.each do |user|
        next if user == current_user

        message = {
          action: 'invited',
          user: user.to_page_context,
        }
        user.pair_programming_waiting_users&.find_by(exercise: @exercise)&.update(status: :invited_to_pg, programming_group: @programming_group)
        ActionCable.server.broadcast("pg_matching_channel_exercise_#{@exercise.id}", message)
      end

      # Check if the user was waiting for a programming group match and update the status
      current_user.pair_programming_waiting_users&.find_by(exercise: @exercise)&.update(status: :created_pg, programming_group: @programming_group)

      # Just set the programming group id in the session for the creator of the group, so that the user can be redirected.
      session[:pg_id] = @programming_group.id

      # Don't return a specific value from this block, so that the default is used.
      nil
    end
  end

  def update
    myparams = programming_group_params || {}
    @members = @programming_group.programming_group_memberships.includes(:user)
    myparams[:users] = @members.where(id: myparams&.fetch(:programming_group_membership_ids, [])&.compact_blank).map(&:user)
    update_and_respond(object: @programming_group, params: myparams)
  end

  def destroy
    session.delete(:pg_id) if current_contributor == @programming_group
    destroy_and_respond(object: @programming_group)
  end

  private

  def authorize!
    raise Pundit::NotAuthorizedError if @programming_group.present? && @exercise.present? && @programming_group.exercise != @exercise

    authorize(@programming_group || @programming_groups)
  end

  def programming_group_params
    params.require(:programming_group).permit(:programming_partner_ids, programming_group_membership_ids: []) if params[:programming_group].present?
  end

  def set_exercise_and_authorize
    @exercise = Exercise.find(params[:exercise_id])
    authorize(@exercise, :implement?)
  end

  def set_programming_group_and_authorize
    @programming_group = ProgrammingGroup.find(params[:id])
    authorize!
  end

  def redirect_to_exercise
    skip_authorization
    redirect_to(implement_exercise_path(@exercise),
      notice: t("sessions.create_through_lti.session_#{lti_outcome_service?(@exercise, current_user) ? 'with' : 'without'}_outcome", consumer: @consumer))
  end
end
