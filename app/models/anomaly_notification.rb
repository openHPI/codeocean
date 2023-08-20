# frozen_string_literal: true

class AnomalyNotification < ApplicationRecord
  include Creation
  belongs_to :exercise
  belongs_to :exercise_collection
end
