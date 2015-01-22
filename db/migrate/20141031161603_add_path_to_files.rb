class AddPathToFiles < ActiveRecord::Migration
  def change
    add_column :files, :path, :string
  end
end
