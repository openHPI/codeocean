# frozen_string_literal: true

class RemoveNotNullConstraintsFromInternalUsers < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:internal_users, :crypted_password, true)
    change_column_null(:internal_users, :salt, true)
  end
end
