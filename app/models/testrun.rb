# frozen_string_literal: true

class Testrun < ApplicationRecord
  belongs_to :file, class_name: 'CodeOcean::File', optional: true
  belongs_to :submission
  belongs_to :testrun_execution_environment, optional: true, dependent: :destroy
  has_many :testrun_messages, dependent: :destroy

  enum status: {
    ok: 0,
    failed: 1,
    container_depleted: 2,
    timeout: 3,
    out_of_memory: 4,
    terminated_by_client: 5,
  }, _default: :ok, _prefix: true

  validates :exit_code, numericality: {only_integer: true, min: 0, max: 255}, allow_nil: true
  validates :status, presence: true

  def log
    testrun_messages.output.select(:log).map(&:log).join.presence
  end
end
