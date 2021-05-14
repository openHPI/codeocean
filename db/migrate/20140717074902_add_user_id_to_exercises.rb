# frozen_string_literal: true

class AddUserIdToExercises < ActiveRecord::Migration[4.2]
  def change
    add_reference :exercises, :user
  end
end
