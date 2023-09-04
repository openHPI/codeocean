# frozen_string_literal: true

class Event::SynchronizedEditor < ApplicationRecord
  self.table_name = 'events_synchronized_editor'

  include Creation

  belongs_to :programming_group
  belongs_to :study_group
  belongs_to :file, class_name: 'CodeOcean::File'

  enum command: {
    editor_change: 0,
    connection_change: 1,
    hello: 2,
    ### TODO: Kira's commands
  }, _prefix: true

  enum status: {
    connected: 0,
    disconnected: 1,
    ### TODO: connected, disconnected ...
  }, _prefix: true

  enum action: {
    insertText: 0,
    insertLines: 1,
    removeText: 2,
    removeLines: 3,
    changeFold: 4,
    removeFold: 5,
    ### TODO: AceEditor Actions: insertText, insertLines, removeText, removesLines, ...
  }, _prefix: true

  validates :status, presence: true, if: -> { command_connection_change? }
  validates :action, presence: true, if: -> { command_editor_change? }
  validates :range_start_row, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { command_editor_change? }
  validates :range_start_column, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { command_editor_change? }
  validates :range_end_row, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { command_editor_change? }
  validates :range_end_column, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: -> { command_editor_change? }
  validates :nl, inclusion: {in: %W[\n \r\n]}, if: -> { action_removeLines? }

  validate :either_lines_or_text

  def self.create_for_editor_change(event, user, programming_group)
    event_copy = event.deep_dup
    file = event_copy.delete(:active_file)
    delta = event_copy.delete(:delta)[:data]
    range = delta.delete(:range)

    create!(
      user:,
      programming_group:,
      study_group_id: user.current_study_group_id,
      command: event_copy.delete(:command),
      action: delta.delete(:action),
      file_id: file[:id],
      range_start_row: range[:start][:row],
      range_start_column: range[:start][:column],
      range_end_row: range[:end][:row],
      range_end_column: range[:end][:column],
      text: delta.delete(:text),
      nl: delta.delete(:nl),
      lines: delta.delete(:lines),
      data: data_attribute(event_copy, delta)
    )
  end

  def self.data_attribute(event, delta)
    event[:delta] = {data: delta} if delta.present?
    event.presence if event.present? # TODO: As of now, we are storing the `current_user_id` most of the times. Intended?
  end
  private_class_method :data_attribute

  private

  def strip_strings
    # trim whitespace from beginning and end of string attributes
    # except the `text` and `nl` of Event::SynchronizedEditor
    attribute_names.without('text', 'nl').each do |name|
      if send(name.to_sym).respond_to?(:strip)
        send("#{name}=".to_sym, send(name).strip)
      end
    end
  end

  def either_lines_or_text
    if [lines, text].count(&:present?) > 1
      errors.add(:text, "can't be present if lines is also present")
    end
  end
end
