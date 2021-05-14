# frozen_string_literal: true

class AddIndentSizeToExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    add_column :execution_environments, :indent_size, :integer
  end
end
