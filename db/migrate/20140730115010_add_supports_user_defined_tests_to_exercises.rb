class AddSupportsUserDefinedTestsToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :supports_user_defined_tests, :boolean
  end
end
