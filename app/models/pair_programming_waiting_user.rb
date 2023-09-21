# frozen_string_literal: true

class PairProgrammingWaitingUser < ApplicationRecord
  include Creation

  belongs_to :exercise
  belongs_to :programming_group, optional: true

  enum status: {
    waiting: 0,
    joined_pg: 1,
    disconnected: 2,
    worked_alone: 3,
    created_pg: 4,
    invited_to_pg: 5,
  }, _prefix: true

  validates :user_id, uniqueness: {scope: %i[exercise_id user_type]}
  validates :programming_group_id, presence: true, if: -> { status_joined_pg? || status_created_pg? || status_invited_to_pg? }

  after_save :capture_event

  def capture_event
    Event.create(category: 'pp_matching', user:, exercise:, data: status.to_s)
  end
end
