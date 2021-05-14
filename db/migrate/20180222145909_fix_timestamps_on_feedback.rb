# frozen_string_literal: true

class FixTimestampsOnFeedback < ActiveRecord::Migration[4.2]
  def up
    change_column_default(:user_exercise_feedbacks, :created_at, nil)
    change_column_default(:user_exercise_feedbacks, :updated_at, nil)
  end

  def down; end
end
