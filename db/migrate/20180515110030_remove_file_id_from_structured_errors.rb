# frozen_string_literal: true

class RemoveFileIdFromStructuredErrors < ActiveRecord::Migration[4.2]
  def change
    remove_column :structured_errors, :file_id
  end
end
