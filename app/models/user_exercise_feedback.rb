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
    'User Exercise Feedback'
  end

  def anomaly_notification
    AnomalyNotification.where({exercise_id: exercise.id, user_id:, user_type:})
      .where('created_at < ?', created_at).order('created_at DESC').to_a.first
  end
end
