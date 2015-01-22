class AddHelpToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :help, :text
  end
end
