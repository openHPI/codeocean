class AddTemplateTestCodeToExercises < ActiveRecord::Migration
  def change
    add_column :exercises, :template_test_code, :text
  end
end
