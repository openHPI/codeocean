# frozen_string_literal: true

class AddTestCodeToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :test_code, :text
  end
end
