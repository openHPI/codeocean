class AddInstructionsToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :instructions, :text
  end
end
