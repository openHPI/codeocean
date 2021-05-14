# frozen_string_literal: true

class AddRoleToExternalUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :external_users, :role, :string, default: 'learner', null: false
  end
end
