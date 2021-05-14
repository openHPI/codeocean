# frozen_string_literal: true

class AddRunCommandToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :run_command, :string
  end
end
