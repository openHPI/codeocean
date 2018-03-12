class AddDefaultExecutionEnvironmentToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :default_execution_environment, :boolean, :default => false
  end
end
