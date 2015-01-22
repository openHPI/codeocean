class RemoveFileTypeRelatedColumnsFromExecutionEnvironments < ActiveRecord::Migration
  def change
    remove_column :execution_environments, :editor_mode, :string
    remove_column :execution_environments, :file_extension, :string
    remove_column :execution_environments, :indent_size, :integer
  end
end
