# frozen_string_literal: true

class AddAllowFileCreationToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :allow_file_creation, :boolean
  end
end
