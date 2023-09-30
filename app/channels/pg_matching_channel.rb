# frozen_string_literal: true

class PgMatchingChannel < ApplicationCable::Channel
  def subscribed
    set_and_authorize_exercise

    stream_from specific_channel unless subscription_rejected?
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    @current_waiting_user.status_disconnected! if @current_waiting_user&.reload&.status_waiting?

    stop_all_streams
  end

  def waiting_for_match
    if (existing_programming_group = current_user.programming_groups.find_by(exercise: @exercise))
      message = {action: 'joined_pg', users: existing_programming_group.users.map(&:to_page_context)}
      ActionCable.server.broadcast(specific_channel, message)
      return
    end

    @current_waiting_user = PairProgrammingWaitingUser.find_or_initialize_by(user: current_user, exercise: @exercise)
    @current_waiting_user.status_waiting!

    match_waiting_users
  end

  private

  def match_waiting_users
    # Check if there is another waiting user for this exercise
    waiting_user = PairProgrammingWaitingUser.where(exercise: @exercise, status: :waiting).where.not(user: current_user).order(created_at: :asc).first
    return if waiting_user.blank?

    # If there is another waiting user, create a programming group with both users
    match = [waiting_user, @current_waiting_user]
    # Create the programming group. Note that an unhandled exception will be raised if the programming group
    # is not valid (i.e., if one of the users already joined a programming group for this exercise).
    pg = ProgrammingGroup.create!(exercise: @exercise, users: match.map(&:user))
    match.each {|wu| wu.update(status: :joined_pg, programming_group: pg) }
    ActionCable.server.broadcast(specific_channel, {action: 'joined_pg', users: pg.users.map(&:to_page_context)})
  end

  def specific_channel
    "pg_matching_channel_exercise_#{@exercise.id}"
  end

  def set_and_authorize_exercise
    @exercise = Exercise.find(params[:exercise_id])
    reject unless ExercisePolicy.new(current_user, @exercise).implement?
  rescue ActiveRecord::RecordNotFound
    reject
  end
end
