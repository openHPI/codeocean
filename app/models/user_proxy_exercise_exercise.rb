# frozen_string_literal: true

class UserProxyExerciseExercise < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :exercise
  belongs_to :proxy_exercise

  validates :user_id, uniqueness: {scope: %i[proxy_exercise_id user_type]}
end
