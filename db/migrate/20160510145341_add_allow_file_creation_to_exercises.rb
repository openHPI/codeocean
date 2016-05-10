class AddAllowFileCreationToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :allow_file_creation, :boolean
  end
end
