class AddUserToExerciseCollection < ActiveRecord::Migration
  def change
    add_reference :exercise_collections, :user,  polymorphic: true, index: true
  end
end
