class AddReasonToUserProxyExerciseExercise < ActiveRecord::Migration
  def change
    change_table :user_proxy_exercise_exercises do |t|
      t.string :reason
    end
  end
end
