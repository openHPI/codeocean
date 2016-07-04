class RemoveTeams < ActiveRecord::Migration
  def change
    remove_column :exercises, :team_id, :integer
    drop_table :teams
    drop_table :internal_users_teams
  end
end
