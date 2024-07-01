# frozen_string_literal: true

class AddPoolSizeToExecutionEnvironments < ActiveRecord::Migration[4.2]
  class ExecutionEnvironment < ApplicationRecord
  end

  def change
    add_column :execution_environments, :pool_size, :integer

    reversible do |direction|
      direction.up do
        ExecutionEnvironment.update(pool_size: 0)
      end
    end
  end
end
