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

  def to_s
    'Pair Programming Exercise Feedback'
  end
end
