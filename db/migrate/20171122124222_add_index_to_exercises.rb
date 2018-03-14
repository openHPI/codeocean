class AddIndexToExercises < ActiveRecord::Migration
  def change
    add_index :exercises, :id
  end
end
