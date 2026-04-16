# frozen_string_literal: true

class AddDeletedAtToExternalUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :external_users, :deleted_at, :datetime, null: true, default: nil
  end
end
