# frozen_string_literal: true

class AddHideFileTreeToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :hide_file_tree, :boolean
  end
end
