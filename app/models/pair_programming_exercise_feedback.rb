# frozen_string_literal: true

class PairProgrammingExerciseFeedback < ApplicationRecord
  include Creation

  belongs_to :exercise
  belongs_to :submission
  belongs_to :study_group
  belongs_to :programming_group, optional: true
  has_one :execution_environment, through: :exercise

  scope :intermediate, -> { where.not(normalized_score: 1.00) }
  scope :final, -> { where(normalized_score: 1.00) }

  enum difficulty: {
    too_easy: 0,
    bit_too_easy: 1,
    just_right: 2,
    bit_too_difficult: 3,
    too_difficult: 4,
  }, _prefix: true

  enum user_estimated_worktime: {
    less_5min: 0,
    between_5_and_10min: 1,
    between_10_and_20min: 2,
    between_20_and_30min: 3,
    more_30min: 4,
  }, _prefix: true

  enum reason_work_alone: {
    found_no_partner: 0,
    too_difficult_to_find_partner: 1,
    faster_alone: 2,
    not_working_with_strangers: 3,
    prefer_to_work_alone: 4,
    accidentally_alone: 5,
    other: 6,
  }, _prefix: true

  def to_s
    "Pair Programming Exercise Feedback #{id}"
  end
end
