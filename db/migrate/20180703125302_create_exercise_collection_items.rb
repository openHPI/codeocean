# frozen_string_literal: true

class CreateExerciseCollectionItems < ActiveRecord::Migration[4.2]
  def up
    rename_table :exercise_collections_exercises, :exercise_collection_items
    add_column :exercise_collection_items,  :position, :integer, default: 0, null: false
    add_column :exercise_collection_items,  :id, :primary_key
  end

  def down
    remove_column :exercise_collection_items,  :position
    remove_column :exercise_collection_items,  :id
    rename_table :exercise_collection_items, :exercise_collections_exercises
  end
end
