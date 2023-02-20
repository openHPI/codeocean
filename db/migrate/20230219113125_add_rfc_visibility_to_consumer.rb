# frozen_string_literal: true

class AddRfcVisibilityToConsumer < ActiveRecord::Migration[7.0]
  def change
    add_column :consumers, :rfc_visibility, :integer, limit: 1, null: false, default: 0, comment: 'Used as enum in Rails'
  end
end
