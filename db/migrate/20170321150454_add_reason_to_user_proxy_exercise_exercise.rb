# frozen_string_literal: true

class AddReasonToUserProxyExerciseExercise < ActiveRecord::Migration[4.2]
  def change
    change_table :user_proxy_exercise_exercises do |t|
      t.string :reason
    end
  end
end
