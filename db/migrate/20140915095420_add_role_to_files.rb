class AddRoleToFiles < ActiveRecord::Migration
  def change
    add_column :files, :role, :string
  end
end
