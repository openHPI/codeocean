class AddTestingFrameworkToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :testing_framework, :string
  end
end
