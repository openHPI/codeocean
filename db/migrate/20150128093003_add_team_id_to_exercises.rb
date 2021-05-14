# frozen_string_literal: true

class AddTeamIdToExercises < ActiveRecord::Migration[4.2]
  def change
    add_reference :exercises, :team
  end
end
