# frozen_string_literal: true

class SynchronizedEditorChannel < ApplicationCable::Channel
  def subscribed
    stream_from specific_channel
    ActionCable.server.broadcast(specific_channel, {command: 'connection_change', status: 'connected', current_user_id: current_user.id, current_user_name: current_user.name})
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
    ActionCable.server.broadcast(specific_channel, {command: 'connection_change', status: 'disconnected', current_user_id: current_user.id, current_user_name: current_user.name})
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

  def send_hello
    ActionCable.server.broadcast(specific_channel, {command: 'hello', status: 'connected', current_user_id: current_user.id, current_user_name: current_user.name})
  end
end
