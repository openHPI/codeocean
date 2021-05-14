# frozen_string_literal: true

class AddAnomalyDetectionFlagToExerciseCollection < ActiveRecord::Migration[4.2]
  def change
    add_column :exercise_collections, :use_anomaly_detection, :boolean, default: false
  end
end
