class UserExerciseFeedback < ActiveRecord::Base
  include Creation

  belongs_to :exercise
  has_one :execution_environment, through: :exercise

  validates :user_id, uniqueness: { scope: [:exercise_id, :user_type] }

  def to_s
    "User Exercise Feedback"
  end
end
