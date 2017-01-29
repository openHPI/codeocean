class AddUserFeedback < ActiveRecord::Migration
  def change
    create_table :user_exercise_feedbacks do |t|
      t.belongs_to :exercise, null: false
      t.belongs_to :user, polymorphic: true, null: false
      t.integer :difficulty
      t.integer :working_time_seconds
      t.string :feedback_text
    end
  end
end
