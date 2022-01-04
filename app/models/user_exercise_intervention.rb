# frozen_string_literal: true

class UserExerciseIntervention < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :intervention
  belongs_to :exercise
end
