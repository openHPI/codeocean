# frozen_string_literal: true

class AddTemplateTestCodeToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :template_test_code, :text
  end
end
