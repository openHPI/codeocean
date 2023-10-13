# frozen_string_literal: true

class AddInternalTitleToExercises < ActiveRecord::Migration[7.0]
  def change
    add_column :exercises, :internal_title, :string
    add_index :exercises, :internal_title, using: :gin, opclass: :gin_trgm_ops
  end
end
