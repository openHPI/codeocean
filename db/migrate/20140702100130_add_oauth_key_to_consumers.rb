# frozen_string_literal: true

class AddOauthKeyToConsumers < ActiveRecord::Migration[4.2]
  def change
    add_column :consumers, :oauth_key, :string
  end
end
