# frozen_string_literal: true

class AddPrivilegedExecutionToExecutionEnvironment < ActiveRecord::Migration[6.1]
  def change
    add_column :execution_environments, :privileged_execution, :boolean, default: false, null: false
  end
end
