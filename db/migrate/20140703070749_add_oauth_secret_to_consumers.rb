class AddOauthSecretToConsumers < ActiveRecord::Migration
  def change
    add_column :consumers, :oauth_secret, :string
  end
end
