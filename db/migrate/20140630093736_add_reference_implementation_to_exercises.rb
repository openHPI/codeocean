class AddReferenceImplementationToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :reference_implementation, :text
  end
end
