class CreateInternalUsersTeams < ActiveRecord::Migration
  def change
    create_table :internal_users_teams do |t|
      t.belongs_to :internal_user, index: true
      t.belongs_to :team, index: true
    end
  end
end
