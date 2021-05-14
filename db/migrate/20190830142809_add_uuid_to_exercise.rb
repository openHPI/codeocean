# frozen_string_literal: true

class AddUuidToExercise < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :uuid, :uuid
  end
end
