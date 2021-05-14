# frozen_string_literal: true

class AddNetworkEnabledToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :network_enabled, :boolean

    reversible do |direction|
      direction.up do
        ExecutionEnvironment.update(network_enabled: true)
      end
    end
  end
end
