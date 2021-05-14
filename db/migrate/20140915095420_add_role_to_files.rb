# frozen_string_literal: true

class AddRoleToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :role, :string
  end
end
