# frozen_string_literal: true

class AddExposedPortsToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :exposed_ports, :string
  end
end
