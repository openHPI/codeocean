class RenameEventsTypeToCategory < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :type, :category
  end
end
