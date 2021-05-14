# frozen_string_literal: true

class AddOauthSecretToConsumers < ActiveRecord::Migration[4.2]
  def change
    add_column :consumers, :oauth_secret, :string
  end
end
