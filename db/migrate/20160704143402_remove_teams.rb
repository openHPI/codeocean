class RemoveTeams < ActiveRecord::Migration
  def change
    remove_reference :exercises, :team
    drop_table :teams
    drop_table :internal_users_teams
  end
end
