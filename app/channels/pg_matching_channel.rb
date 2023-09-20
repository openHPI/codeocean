# frozen_string_literal: true

class PgMatchingChannel < ApplicationCable::Channel
  def subscribed
    set_and_authorize_exercise
    stream_from specific_channel
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    @current_waiting_user.status_disconnected! if @current_waiting_user.reload.status_waiting?
    Event.create(category: 'pp_matching', user: current_user, exercise: @exercise, data: 'disconnected')

    stop_all_streams
  end

  def specific_channel
    "pg_matching_channel_exercise_#{@exercise.id}"
  end

  def waiting_for_match
    Event.create(category: 'pp_matching', user: current_user, exercise: @exercise, data: 'waiting')
    @current_waiting_user = PairProgrammingWaitingUser.find_or_initialize_by(user: current_user, exercise: @exercise)
    @current_waiting_user.status_waiting!

    match_waiting_users
  end

  def match_waiting_users
    # Check if there is another waiting user for this exercise
    waiting_user = PairProgrammingWaitingUser.where(exercise: @exercise, status: :waiting).where.not(user: current_user).order(created_at: :asc).first
    if waiting_user.present?
      ProgrammingGroup.create(exercise: @exercise, users: [waiting_user.user, current_user])
      waiting_user.status_joined_pg!
      Event.create(category: 'pp_matching', user: waiting_user.user, exercise: @exercise, data: 'joined_pg')

      @current_waiting_user.status_joined_pg!
      Event.create(category: 'pp_matching', user: current_user, exercise: @exercise, data: 'joined_pg')

      ActionCable.server.broadcast(specific_channel, {action: 'joined_pg', users: [current_user.to_page_context, waiting_user.user.to_page_context]})
    end
  end

  private

  def set_and_authorize_exercise
    @exercise = Exercise.find(params[:exercise_id])
    reject unless ExercisePolicy.new(current_user, @exercise).implement?
  end
end
