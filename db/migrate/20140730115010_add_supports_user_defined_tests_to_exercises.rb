# frozen_string_literal: true

class AddSupportsUserDefinedTestsToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :supports_user_defined_tests, :boolean
  end
end
