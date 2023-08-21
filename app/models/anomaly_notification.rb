# frozen_string_literal: true

class AnomalyNotification < ApplicationRecord
  include ContributorCreation
  belongs_to :exercise
  belongs_to :exercise_collection
end
