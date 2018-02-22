class FixTimestampsOnFeedback < ActiveRecord::Migration
  def change
    change_column_default(:user_exercise_feedbacks, :created_at, nil)
    change_column_default(:user_exercise_feedbacks, :updated_at, nil)
  end
end
