class AddBinaryToFileTypes < ActiveRecord::Migration
  def change
    add_column :file_types, :binary, :boolean
  end
end
