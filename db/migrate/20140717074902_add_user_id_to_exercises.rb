class AddUserIdToExercises < ActiveRecord::Migration
  def change
    add_reference :exercises, :user
  end
end
