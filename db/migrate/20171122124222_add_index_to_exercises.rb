# frozen_string_literal: true

class AddIndexToExercises < ActiveRecord::Migration[4.2]
  def change
    add_index :exercises, :id
  end
end
