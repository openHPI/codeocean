class RemoveFileIdFromExercises < ActiveRecord::Migration
  def change
    remove_reference :exercises, :file
  end
end
