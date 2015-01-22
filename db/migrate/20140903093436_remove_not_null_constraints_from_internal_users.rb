class RemoveNotNullConstraintsFromInternalUsers < ActiveRecord::Migration
  def change
    change_column_null(:internal_users, :crypted_password, true)
    change_column_null(:internal_users, :salt, true)
  end
end
