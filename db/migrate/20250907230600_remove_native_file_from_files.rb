# frozen_string_literal: true

class RemoveNativeFileFromFiles < ActiveRecord::Migration[8.0]
  def up
    if column_exists?(:files, :native_file)
      remove_column :files, :native_file, :string
    end
  end

  def down
    unless column_exists?(:files, :native_file)
      add_column :files, :native_file, :string
    end
  end
end
