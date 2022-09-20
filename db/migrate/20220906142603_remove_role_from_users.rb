# frozen_string_literal: true

class RemoveRoleFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :external_users, :role
    remove_column :internal_users, :role
  end
end
