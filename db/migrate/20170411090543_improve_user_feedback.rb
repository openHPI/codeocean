class ImproveUserFeedback < ActiveRecord::Migration
  def change
    remove_column :user_exercise_feedbacks, :difficulty
    add_column :user_exercise_feedbacks, :difficulty, :string
  end
end
