# frozen_string_literal: true

class AddCpuLimitToExecutionEnvironment < ActiveRecord::Migration[6.1]
  def change
    add_column :execution_environments, :cpu_limit, :integer, null: false, default: 20
  end
end
