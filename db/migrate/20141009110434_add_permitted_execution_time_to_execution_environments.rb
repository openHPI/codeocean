class AddPermittedExecutionTimeToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :permitted_execution_time, :integer
  end
end
