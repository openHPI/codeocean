class AddPublishedToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :published, :boolean
  end
end
