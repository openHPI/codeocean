class ExerciseCollectionItem < ActiveRecord::Base
  belongs_to :exercise_collection
  belongs_to :exercise
end
