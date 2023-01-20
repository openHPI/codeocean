# frozen_string_literal: true

class AddAlgorithmToProxyExercise < ActiveRecord::Migration[7.0]
  def change
    add_column :proxy_exercises, :algorithm, :integer, limit: 1, null: false, default: 0, comment: 'Used as enum in Rails'
  end
end
