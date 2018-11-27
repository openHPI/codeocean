class AddFileIndexToFiles < ActiveRecord::Migration[4.2]
  def change
    add_index(:files, [:context_id, :context_type])
  end
end
