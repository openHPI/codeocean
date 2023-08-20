# frozen_string_literal: true

class UserExerciseIntervention < ApplicationRecord
  include Creation
  belongs_to :intervention
  belongs_to :exercise
end
