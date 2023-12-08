# frozen_string_literal: true

class UserExerciseIntervention < ApplicationRecord
  include ContributorCreation
  belongs_to :intervention
  belongs_to :exercise
end
