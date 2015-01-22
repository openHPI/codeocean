class AddFileIdToExercises < ActiveRecord::Migration
  def change
    add_reference :exercises, :file
  end
end
