# frozen_string_literal: true

class Event::SynchronizedEditor < ApplicationRecord
  self.table_name = 'events_synchronized_editor'

  include Creation

  belongs_to :programming_group
  belongs_to :study_group
  belongs_to :file, class_name: 'CodeOcean::File', optional: true

  enum :action, {
    editor_change: 0,
    connection_change: 1,
    connection_status: 2,
    current_content: 3,
  }, prefix: true

  enum :status, {
    connected: 0,
    disconnected: 1,
  }, prefix: true

  enum :editor_action, {
    insert: 0,
    remove: 1,
  }, prefix: true

  validates :session_id, presence: true
  validates :status, presence: true, if: -> { action_connection_change? }
  validates :file_id, presence: true, if: -> { action_editor_change? || action_current_content? }
  validates :editor_action, presence: true, if: -> { action_editor_change? }
  validates :range_start_row, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { action_editor_change? }
  validates :range_start_column, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { action_editor_change? }
  validates :range_end_row, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { action_editor_change? }
  validates :range_end_column, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { action_editor_change? }
  validates :lines, presence: true, if: -> { action_editor_change? }
  validate :lines_not_nil, if: -> { action_current_content? }

  def self.create_for_editor_change(event, user, programming_group)
    event_copy = event.deep_dup
    file = event_copy.delete(:active_file)
    delta = event_copy.delete(:delta)
    start_range = delta.delete(:start)
    end_range = delta.delete(:end)

    create!(
      user:,
      programming_group:,
      study_group_id: user.current_study_group_id,
      action: event_copy.delete(:action),
      editor_action: delta.delete(:action),
      file_id: file[:id],
      session_id: event_copy.delete(:session_id),
      range_start_row: start_range[:row],
      range_start_column: start_range[:column],
      range_end_row: end_range[:row],
      range_end_column: end_range[:column],
      lines: delta.delete(:lines),
      data: data_attribute(event_copy, delta)
    )
  end

  def self.create_for_current_content(message, user, programming_group)
    message['files'].each do |file|
      create!(
        user:,
        programming_group:,
        study_group_id: user.current_study_group_id,
        action: message['action'],
        file_id: file['file_id'],
        session_id: message['session_id'],
        lines: file['content'].split("\n")
      )
    end
  end

  def self.create_for_connection_change(message, user, programming_group)
    create!(
      user:,
      programming_group:,
      study_group_id: user.current_study_group_id,
      session_id: message[:session_id],
      action: message[:action],
      status: message[:status]
    )
  end

  def self.data_attribute(event, delta)
    event[:delta] = {data: delta} if delta.present?
    event.presence if event.present? # TODO: As of now, we are storing the `session_id` most of the times. Intended?
  end
  private_class_method :data_attribute
end

private

def lines_not_nil
  if lines.nil?
    errors.add(:lines, 'cannot be nil')
  end
end
