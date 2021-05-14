# frozen_string_literal: true

class RemoveFileIdFromExercises < ActiveRecord::Migration[4.2]
  def change
    remove_reference :exercises, :file
  end
end
