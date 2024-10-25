# frozen_string_literal: true

class Testrun < ApplicationRecord
  include Creation
  belongs_to :file, class_name: 'CodeOcean::File', optional: true
  belongs_to :submission
  belongs_to :testrun_execution_environment, optional: true, dependent: :destroy
  has_many :testrun_messages, dependent: :destroy

  CONSOLE_OUTPUT = %w[stdout stderr].freeze
  CAUSES = %w[assess run].freeze

  enum :status, {
    ok: 0,
    failed: 1,
    container_depleted: 2,
    timeout: 3,
    out_of_memory: 4,
    terminated_by_client: 5,
    runner_in_use: 6,
  }, default: :ok, prefix: true

  validates :exit_code, numericality: {only_integer: true, min: 0, max: 255}, allow_nil: true
  validates :status, presence: true
  validates :cause, inclusion: {in: CAUSES}

  def log
    if testrun_messages.loaded?
      testrun_messages.filter {|m| m.cmd_write? && CONSOLE_OUTPUT.include?(m.stream) }.pluck(:log).join.presence
    else
      testrun_messages.output.pluck(:log).join.presence
    end
  end
end
