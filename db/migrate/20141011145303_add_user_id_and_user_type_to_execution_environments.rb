class AddUserIdAndUserTypeToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_reference :execution_environments, :user
    add_column :execution_environments, :user_type, :string
  end
end
