# frozen_string_literal: true

class TestrunMessage < ApplicationRecord
  belongs_to :testrun

  enum cmd: {
    input: 0,
    write: 1,
    clear: 2,
    turtle: 3,
    turtlebatch: 4,
    render: 5,
    exit: 6,
    timeout: 7,
    out_of_memory: 8,
    status: 9,
    hint: 10,
    client_kill: 11,
    exception: 12,
    result: 13,
    canvasevent: 14,
  }, _default: :write, _prefix: true

  enum stream: {
    stdin: 0,
    stdout: 1,
    stderr: 2,
  }, _prefix: true

  validates :cmd, presence: true
  validates :timestamp, presence: true
  validates :stream, length: {minimum: 0, allow_nil: false}, if: -> { cmd_write? }
  validates :log, length: {minimum: 0, allow_nil: false}, if: -> { cmd_write? }
  validate :either_data_or_log

  def self.create_for(testrun, messages)
    messages.map! do |message|
      # We create a new hash and move all known keys
      result = {}
      result[:testrun] = testrun
      result[:log] = message.delete(:log) || (message.delete(:data) if message[:cmd] == :write)
      result[:timestamp] = message.delete :timestamp
      result[:stream] = message.delete :stream
      result[:cmd] = message.delete :cmd
      # The remaining keys will be stored in the `data` column
      result[:data] = message.presence
      result
    end

    # An array with hashes is passed, all are stored
    TestrunMessage.create!(messages)
  end

  def either_data_or_log
    if [data, log].count(&:present?) > 1
      errors.add(log, "can't be present if data is also present")
    end
  end
  private :either_data_or_log
end
