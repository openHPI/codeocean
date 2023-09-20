# frozen_string_literal: true

class PairProgrammingWaitingUser < ApplicationRecord
  include Creation

  belongs_to :exercise

  enum status: {
    waiting: 0,
    joined_pg: 1,
    disconnected: 2,
    worked_alone: 3,
    created_pg: 4,
  }, _prefix: true

  validates :user_id, uniqueness: {scope: %i[exercise_id user_type]}
end
