class AddPoolSizeToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :pool_size, :integer

    reversible do |direction|
      direction.up do
        ExecutionEnvironment.update_all(pool_size: 0)
      end
    end
  end
end
