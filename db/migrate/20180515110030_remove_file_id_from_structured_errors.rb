class RemoveFileIdFromStructuredErrors < ActiveRecord::Migration
  def change
    remove_column :structured_errors, :file_id
  end
end
