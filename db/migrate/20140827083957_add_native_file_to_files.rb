class AddNativeFileToFiles < ActiveRecord::Migration
  def change
    add_column :files, :native_file, :string
  end
end
