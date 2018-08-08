class UserExerciseFeedback < ActiveRecord::Base
  include Creation

  belongs_to :exercise
  has_one :execution_environment, through: :exercise

  validates :user_id, uniqueness: { scope: [:exercise_id, :user_type] }

  def to_s
    "User Exercise Feedback"
  end

  def anomaly_notification
    AnomalyNotification.where({exercise_id: exercise.id, user_id: user_id, user_type: user_type})
        .where("created_at < ?", created_at).order("created_at DESC").to_a.first
  end
end
