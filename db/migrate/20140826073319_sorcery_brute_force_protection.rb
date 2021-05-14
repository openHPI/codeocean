# frozen_string_literal: true

class SorceryBruteForceProtection < ActiveRecord::Migration[4.2]
  def change
    add_column :internal_users, :failed_logins_count, :integer, default: 0
    add_column :internal_users, :lock_expires_at, :datetime, default: nil
    add_column :internal_users, :unlock_token, :string, default: nil
  end
end
