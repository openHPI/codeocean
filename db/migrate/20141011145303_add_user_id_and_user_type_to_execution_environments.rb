# frozen_string_literal: true

class AddUserIdAndUserTypeToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_reference :execution_environments, :user
    add_column :execution_environments, :user_type, :string
  end
end
