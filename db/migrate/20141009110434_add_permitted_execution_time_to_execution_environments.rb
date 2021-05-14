# frozen_string_literal: true

class AddPermittedExecutionTimeToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :permitted_execution_time, :integer
  end
end
