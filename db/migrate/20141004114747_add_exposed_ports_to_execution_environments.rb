class AddExposedPortsToExecutionEnvironments < ActiveRecord::Migration
  def change
    add_column :execution_environments, :exposed_ports, :string
  end
end
