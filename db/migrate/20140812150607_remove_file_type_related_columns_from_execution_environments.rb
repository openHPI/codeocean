# frozen_string_literal: true

class RemoveFileTypeRelatedColumnsFromExecutionEnvironments < ActiveRecord::Migration[4.2]
  def change
    remove_column :execution_environments, :editor_mode, :string
    remove_column :execution_environments, :file_extension, :string
    remove_column :execution_environments, :indent_size, :integer
  end
end
