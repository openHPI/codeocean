class AddTestCommandToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :test_command, :string
  end
end
