class AddAnomalyDetectionFlagToExerciseCollection < ActiveRecord::Migration
  def change
    add_column :exercise_collections, :use_anomaly_detection, :boolean, :default => false
  end
end
