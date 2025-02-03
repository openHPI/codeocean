# frozen_string_literal: true

class AddWebauthnCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :webauthn_credentials do |t|
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :label, null: false
      t.bigint :sign_count, null: false, default: 0
      t.string :transports, array: true, default: []
      t.references :user, polymorphic: true, null: false
      t.timestamp :last_used_at
      t.timestamps

      t.index :external_id, unique: true
    end

    add_column :internal_users, :webauthn_user_id, :string
    add_column :external_users, :webauthn_user_id, :string
  end
end
