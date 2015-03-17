class AddMemoryLimitToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :memory_limit, :integer

    reversible do |direction|
      direction.up do
        ExecutionEnvironment.update_all(memory_limit: DockerClient::DEFAULT_MEMORY_LIMIT)
      end
    end
  end
end
