class UserExerciseIntervention < ActiveRecord::Base

  belongs_to :user, polymorphic: true
  belongs_to :intervention
  belongs_to :exercise

  validates :user, presence: true
  validates :exercise, presence: true
  validates :intervention, presence: true

end