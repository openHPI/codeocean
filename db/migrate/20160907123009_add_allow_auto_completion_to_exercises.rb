class AddAllowAutoCompletionToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :allow_auto_completion, :boolean, default: false
  end
end
