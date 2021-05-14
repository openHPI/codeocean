# frozen_string_literal: true

class AddInstructionsToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :instructions, :text
  end
end
