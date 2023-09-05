# frozen_string_literal: true

class AddPairProgrammingExerciseFeedbacks < ActiveRecord::Migration[7.0]
  def change
    create_table :pair_programming_exercise_feedbacks do |t|
      t.references :exercise, null: false, index: true, foreign_key: true
      t.references :submission, null: false, index: true, foreign_key: true
      t.references :user, polymorphic: true, null: false, index: true
      t.references :programming_group, null: true, index: {name: 'pp_feedback_programming_group'}, foreign_key: true
      t.references :study_group, null: false, index: true, foreign_key: true
      t.integer :difficulty
      t.integer :user_estimated_worktime
      t.integer :reason_work_alone
      t.float :normalized_score

      t.timestamps
    end
  end
end
