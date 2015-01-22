class AddIndentSizeToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :indent_size, :integer
  end
end
