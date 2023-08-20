# frozen_string_literal: true

class UserProxyExerciseExercise < ApplicationRecord
  include Creation
  belongs_to :exercise
  belongs_to :proxy_exercise

  validates :user_id, uniqueness: {scope: %i[proxy_exercise_id user_type]}
end
