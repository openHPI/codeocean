# frozen_string_literal: true

class SorceryUserActivation < ActiveRecord::Migration[4.2]
  def change
    add_column :internal_users, :activation_state, :string, default: nil
    add_column :internal_users, :activation_token, :string, default: nil
    add_column :internal_users, :activation_token_expires_at, :datetime, default: nil
    add_index :internal_users, :activation_token
  end
end
