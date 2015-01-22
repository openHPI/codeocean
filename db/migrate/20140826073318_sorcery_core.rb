class SorceryCore < ActiveRecord::Migration
  def change
    InternalUser.delete_all
    add_column :internal_users, :crypted_password, :string, null: false
    add_column :internal_users, :salt, :string, null: false
    add_index :internal_users, :email, unique: true
  end
end
