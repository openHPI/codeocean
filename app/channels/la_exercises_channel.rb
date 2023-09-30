# frozen_string_literal: true

class LaExercisesChannel < ApplicationCable::Channel
  def subscribed
    set_and_authorize_exercise
    set_and_authorize_study_group

    stream_from specific_channel unless subscription_rejected?
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def specific_channel
    "la_exercises_#{@exercise.id}_channel_study_group_#{@study_group.id}"
  end

  def set_and_authorize_exercise
    @exercise = Exercise.find(params[:exercise_id])
    reject unless ExercisePolicy.new(current_user, @exercise).implement?
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def set_and_authorize_study_group
    @study_group = @exercise.study_groups.find(params[:study_group_id])
    reject unless StudyGroupPolicy.new(current_user, @study_group).stream_la?
  rescue ActiveRecord::RecordNotFound
    reject
  end
end
