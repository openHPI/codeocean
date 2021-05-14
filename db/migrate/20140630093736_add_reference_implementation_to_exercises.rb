# frozen_string_literal: true

class AddReferenceImplementationToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :reference_implementation, :text
  end
end
