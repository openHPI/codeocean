class UserExerciseFeedback < ActiveRecord::Base

  belongs_to :user, polymorphic: true
  belongs_to :exercise

  validates :user_id, uniqueness: { scope: [:exercise_id, :user_type] }

end