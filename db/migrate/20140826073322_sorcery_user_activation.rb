class SorceryUserActivation < ActiveRecord::Migration
  def change
    add_column :internal_users, :activation_state, :string, default: nil
    add_column :internal_users, :activation_token, :string, default: nil
    add_column :internal_users, :activation_token_expires_at, :datetime, default: nil
    add_index :internal_users, :activation_token
  end
end
