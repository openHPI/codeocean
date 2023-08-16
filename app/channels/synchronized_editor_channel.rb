# frozen_string_literal: true

class SynchronizedEditorChannel < ApplicationCable::Channel
  def subscribed
    stream_from specific_channel
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def specific_channel
    reject unless ProgrammingGroupPolicy.new(current_user, programming_group).stream_sync_editor?
    "synchronized_editor_channel_group_#{programming_group.id}"
  end

  def programming_group
    current_contributor if current_contributor.programming_group?
  end

  def send_changes(message)
    ActionCable.server.broadcast(specific_channel, message['delta_with_user_id'])
  end
end
