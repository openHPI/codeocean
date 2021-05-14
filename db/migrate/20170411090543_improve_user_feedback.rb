# frozen_string_literal: true

class ImproveUserFeedback < ActiveRecord::Migration[4.2]
  def change
    add_column :user_exercise_feedbacks, :user_estimated_worktime, :integer
  end
end
