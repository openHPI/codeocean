# frozen_string_literal: true

class AddUnpublishedToExercise < ActiveRecord::Migration[5.2]
  def change
    add_column :exercises, :unpublished, :boolean, default: false
  end
end
