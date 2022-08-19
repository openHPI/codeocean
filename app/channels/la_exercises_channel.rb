# frozen_string_literal: true

class LaExercisesChannel < ApplicationCable::Channel
  def subscribed
    stream_from specific_channel
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def specific_channel
    reject unless StudyGroupPolicy.new(current_user, StudyGroup.find(params[:study_group_id])).stream_la?
    "la_exercises_#{params[:exercise_id]}_channel_study_group_#{params[:study_group_id]}"
  end
end
