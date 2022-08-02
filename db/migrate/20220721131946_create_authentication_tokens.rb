# frozen_string_literal: true

class CreateAuthenticationTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :authentication_tokens, id: :uuid do |t|
      t.string :shared_secret, null: false, index: {unique: true}
      t.references :user, polymorphic: true, null: false
      t.date :expire_at, null: false
      t.timestamps
    end
  end
end
