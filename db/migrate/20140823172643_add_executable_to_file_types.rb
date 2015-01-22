class AddExecutableToFileTypes < ActiveRecord::Migration
  def change
    add_column :file_types, :executable, :boolean
  end
end
