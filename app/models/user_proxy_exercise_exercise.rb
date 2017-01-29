class UserProxyExerciseExercise < ActiveRecord::Base

  belongs_to :user, polymorphic: true
  belongs_to :exercise
  belongs_to :proxy_exercise

  validates :user_id, presence: true
  validates :user_type, presence: true
  validates :exercise_id, presence: true
  validates :proxy_exercise_id, presence: true

  validates :user_id, uniqueness: { scope: [:proxy_exercise_id, :user_type] }

end