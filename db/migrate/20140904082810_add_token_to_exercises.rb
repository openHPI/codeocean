# frozen_string_literal: true

class AddTokenToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :token, :string
  end
end
