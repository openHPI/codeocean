# frozen_string_literal: true

class SynchronizedEditorChannel < ApplicationCable::Channel
  def subscribed
    set_and_authorize_exercise
    authorize_programming_group

    stream_from specific_channel unless subscription_rejected?

    # We generate a session_id for the user and send it to the client
    @session_id = SecureRandom.uuid

    # We need to wait for the subscription to be confirmed before we can send further messages
    send_after_streaming_confirmed do
      connection.transmit identifier: @identifier, message: {action: :session_id, session_id: @session_id}

      message = create_message('connection_change', 'connected')
      Event::SynchronizedEditor.create_for_connection_change(message, current_user, programming_group)
      ActionCable.server.broadcast(specific_channel, message)
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
    return unless programming_group && @session_id

    message = create_message('connection_change', 'disconnected')

    Event::SynchronizedEditor.create_for_connection_change(message, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, message)
  end

  def editor_change(message)
    change = message.deep_symbolize_keys

    Event::SynchronizedEditor.create_for_editor_change(change, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, change)
  end

  def connection_status
    message = create_message('connection_status', 'connected')

    Event::SynchronizedEditor.create_for_connection_change(message, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, message)
  end

  def current_content(message)
    Event::SynchronizedEditor.create_for_current_content(message, current_user, programming_group)
    ActionCable.server.broadcast(specific_channel, message)
  end

  def reset_content(content)
    message = create_reset_content_message(content)
    ActionCable.server.broadcast(specific_channel, message)
  end

  private

  def specific_channel
    "synchronized_editor_channel_group_#{programming_group.id}"
  end

  def programming_group
    current_contributor if current_contributor.programming_group?
  end

  def create_message(action, status)
    {
      action:,
      status:,
      user: current_user.to_page_context,
      session_id: @session_id,
    }
  end

  def create_reset_content_message(content)
    {
      action: content['action'],
      files: content['files'],
      user: current_user.to_page_context,
      session_id: @session_id,
    }
  end

  def set_and_authorize_exercise
    @exercise = Exercise.find(params[:exercise_id])
    reject unless ExercisePolicy.new(current_user, @exercise).implement?
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def authorize_programming_group
    reject unless ProgrammingGroupPolicy.new(current_user, programming_group).stream_sync_editor?
  end
end
