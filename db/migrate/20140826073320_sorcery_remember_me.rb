class SorceryRememberMe < ActiveRecord::Migration
  def change
    add_column :internal_users, :remember_me_token, :string, default: nil
    add_column :internal_users, :remember_me_token_expires_at, :datetime, default: nil
    add_index :internal_users, :remember_me_token
  end
end
