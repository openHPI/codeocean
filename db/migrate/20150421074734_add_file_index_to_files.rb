class AddFileIndexToFiles < ActiveRecord::Migration
  def change
    add_index(:files, [:context_id, :context_type])
  end
end
