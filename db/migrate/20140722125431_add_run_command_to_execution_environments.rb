class AddRunCommandToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :run_command, :string
  end
end
