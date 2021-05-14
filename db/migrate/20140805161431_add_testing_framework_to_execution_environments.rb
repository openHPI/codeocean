# frozen_string_literal: true

class AddTestingFrameworkToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :testing_framework, :string
  end
end
