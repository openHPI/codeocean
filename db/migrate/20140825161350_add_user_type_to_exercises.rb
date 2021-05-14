# frozen_string_literal: true

class AddUserTypeToExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :exercises, :user_type, :string
  end
end
