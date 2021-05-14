# frozen_string_literal: true

class AddIndexToUnpublishedExercises < ActiveRecord::Migration[5.2]
  def change
    add_index(:exercises, :id, where: 'NOT unpublished', name: :index_unpublished_exercises)
  end
end
