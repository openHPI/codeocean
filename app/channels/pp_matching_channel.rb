# frozen_string_literal: true

class PpMatchingChannel < ApplicationCable::Channel
  def subscribed
    stream_from specific_channel
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def specific_channel
    "pp_matching_channel_exercise_#{params[:exercise_id]}"
  end
end
