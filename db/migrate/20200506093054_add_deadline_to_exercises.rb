# frozen_string_literal: true

class AddDeadlineToExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :submission_deadline, :datetime, null: true, default: nil
    add_column :exercises, :late_submission_deadline, :datetime, null: true, default: nil
  end
end
