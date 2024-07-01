# frozen_string_literal: true

class AddForeignKeysToAnomalyNotifications < ActiveRecord::Migration[7.0]
  class AnomalyNotification < ApplicationRecord
    belongs_to :exercise
  end

  class Exercise < ApplicationRecord
    has_many :anomaly_notifications
  end

  def change
    up_only do
      # We cannot add a foreign key to a table that has rows that violate the constraint.
      AnomalyNotification.where.not(exercise_id: Exercise.select(:id)).delete_all
    end

    change_column_null :anomaly_notifications, :contributor_id, false
    change_column_null :anomaly_notifications, :contributor_type, false

    change_column_null :anomaly_notifications, :exercise_id, false
    add_foreign_key :anomaly_notifications, :exercises

    change_column_null :anomaly_notifications, :exercise_collection_id, false
    add_foreign_key :anomaly_notifications, :exercise_collections
  end
end
