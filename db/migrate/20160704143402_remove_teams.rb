# frozen_string_literal: true

class RemoveTeams < ActiveRecord::Migration[4.2]
  def change
    remove_reference :exercises, :team
    drop_table :teams
    drop_table :internal_users_teams
  end
end
