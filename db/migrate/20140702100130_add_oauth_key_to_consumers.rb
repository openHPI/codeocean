class AddOauthKeyToConsumers < ActiveRecord::Migration
  def change
    add_column :consumers, :oauth_key, :string
  end
end
