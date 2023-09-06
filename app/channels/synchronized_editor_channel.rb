# frozen_string_literal: true

class SynchronizedEditorChannel < ApplicationCable::Channel
  def subscribed
    stream_from specific_channel
    message = create_message('connection_change', 'connected')

    Event::SynchronizedEditor.create_for_connection_change(message, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, message)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
    message = create_message('connection_change', 'disconnected')

    Event::SynchronizedEditor.create_for_connection_change(message, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, message)
  end

  def specific_channel
    reject unless ProgrammingGroupPolicy.new(current_user, programming_group).stream_sync_editor?
    "synchronized_editor_channel_group_#{programming_group.id}"
  end

  def programming_group
    current_contributor if current_contributor.programming_group?
  end

  def editor_change(message)
    change = message.deep_symbolize_keys

    Event::SynchronizedEditor.create_for_editor_change(change, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, change)
  end

  def connection_status
    ActionCable.server.broadcast(specific_channel, create_message('connection_status', 'connected'))
  end

  def create_message(action, status)
    {
      action:,
      status:,
      user: current_user.to_page_context,
    }
  end
end
