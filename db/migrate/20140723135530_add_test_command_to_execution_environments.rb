# frozen_string_literal: true

class AddTestCommandToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :test_command, :string
  end
end
