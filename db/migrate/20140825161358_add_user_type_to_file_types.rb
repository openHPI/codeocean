class AddUserTypeToFileTypes < ActiveRecord::Migration
  def change
    add_column :file_types, :user_type, :string
  end
end
