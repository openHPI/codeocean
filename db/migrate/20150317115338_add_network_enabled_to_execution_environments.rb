class AddNetworkEnabledToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :network_enabled, :boolean

    reversible do |direction|
      direction.up do
        ExecutionEnvironment.update_all(network_enabled: true)
      end
    end
  end
end
