# frozen_string_literal: true

class CreateAnomalyNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :anomaly_notifications do |t|
      t.belongs_to :user, polymorphic: true, index: true
      t.belongs_to :exercise, index: true
      t.belongs_to :exercise_collection, index: true
      t.string :reason
      t.timestamps
    end
  end
end
