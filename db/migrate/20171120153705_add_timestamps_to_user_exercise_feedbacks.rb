class AddTimestampsToUserExerciseFeedbacks < ActiveRecord::Migration[4.2]
  def up
    add_column :user_exercise_feedbacks, :created_at, :datetime, null: false, default: Time.now
    add_column :user_exercise_feedbacks, :updated_at, :datetime, null: false, default: Time.now
  end
end
