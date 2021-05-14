# frozen_string_literal: true

class AddAllowAutoCompletionToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :allow_auto_completion, :boolean, default: false
  end
end
