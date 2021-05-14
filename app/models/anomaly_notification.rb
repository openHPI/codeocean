# frozen_string_literal: true

class AnomalyNotification < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :exercise
  belongs_to :exercise_collection
end
