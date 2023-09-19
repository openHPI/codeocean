# frozen_string_literal: true

class PgMatchingChannel < ApplicationCable::Channel
  def subscribed
    set_and_authorize_exercise
    stream_from specific_channel
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def specific_channel
    "pg_matching_channel_exercise_#{@exercise.id}"
  end

  private

  def set_and_authorize_exercise
    @exercise = Exercise.find(params[:exercise_id])
    reject unless ExercisePolicy.new(current_user, @exercise).implement?
  end
end
