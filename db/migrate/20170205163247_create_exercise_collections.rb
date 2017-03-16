class CreateExerciseCollections < ActiveRecord::Migration
  def change
    create_table :exercise_collections do |t|
      t.string :name
      t.timestamps
    end

    create_table :exercise_collections_exercises, id: false do |t|
      t.belongs_to :exercise_collection, index: true
      t.belongs_to :exercise, index: true
    end

  end
end
