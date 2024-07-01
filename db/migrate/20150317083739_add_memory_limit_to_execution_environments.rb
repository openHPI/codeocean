# frozen_string_literal: true

class AddMemoryLimitToExecutionEnvironments < ActiveRecord::Migration[4.2]
  class ExecutionEnvironment < ApplicationRecord
    DEFAULT_MEMORY_LIMIT = 256
  end

  def change
    add_column :execution_environments, :memory_limit, :integer

    reversible do |direction|
      direction.up do
        ExecutionEnvironment.update(memory_limit: ExecutionEnvironment::DEFAULT_MEMORY_LIMIT)
      end
    end
  end
end
