class RenamePublishedToPublic < ActiveRecord::Migration
  def change
    rename_column :exercises, :published, :public
  end
end
