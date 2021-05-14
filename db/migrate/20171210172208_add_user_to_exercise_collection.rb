# frozen_string_literal: true

class AddUserToExerciseCollection < ActiveRecord::Migration[4.2]
  def change
    add_reference :exercise_collections, :user, polymorphic: true, index: true
  end
end
