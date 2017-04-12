class ImproveUserFeedback < ActiveRecord::Migration
  def change
    add_column :user_exercise_feedbacks, :user_estimated_worktime, :integer
  end
end
