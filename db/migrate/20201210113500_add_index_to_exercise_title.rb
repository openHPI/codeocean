# frozen_string_literal: true

class AddIndexToExerciseTitle < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pg_trgm'
    add_index :exercises, :title, using: :gin, opclass: :gin_trgm_ops
  end
end
