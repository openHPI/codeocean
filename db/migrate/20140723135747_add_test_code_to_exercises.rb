class AddTestCodeToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :test_code, :text
  end
end
