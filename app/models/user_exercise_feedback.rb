# frozen_string_literal: true

class UserExerciseFeedback < ApplicationRecord
  include Creation

  belongs_to :exercise
  belongs_to :submission, optional: true
  has_one :execution_environment, through: :exercise

  validates :user_id, uniqueness: {scope: %i[exercise_id user_type]}

  scope :intermediate, -> { where.not(normalized_score: 1.00) }
  scope :final, -> { where(normalized_score: 1.00) }

  def to_s
    "User Exercise Feedback #{id}"
  end

  def anomaly_notification
    AnomalyNotification
      .where(exercise:, contributor: user, created_at: ...created_at)
      .order(created_at: :desc)
      .first
  end

  def self.parent_resource
    Exercise
  end
end
