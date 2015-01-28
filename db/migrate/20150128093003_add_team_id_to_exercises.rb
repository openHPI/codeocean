class AddTeamIdToExercises < ActiveRecord::Migration
  def change
    add_reference :exercises, :team
  end
end
