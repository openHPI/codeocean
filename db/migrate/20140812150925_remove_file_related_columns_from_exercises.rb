# frozen_string_literal: true

class RemoveFileRelatedColumnsFromExercises < ActiveRecord::Migration[4.2]
  def change
    remove_column :exercises, :reference_implementation, :text
    remove_column :exercises, :supports_user_defined_tests, :boolean
    remove_column :exercises, :template_code, :text
    remove_column :exercises, :template_test_code, :text
    remove_column :exercises, :test_code, :text
  end
end
