# frozen_string_literal: true

class ExerciseCollectionItem < ApplicationRecord
  belongs_to :exercise_collection
  belongs_to :exercise
end
