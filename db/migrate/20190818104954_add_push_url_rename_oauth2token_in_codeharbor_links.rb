class AddPushUrlRenameOauth2tokenInCodeharborLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :codeharbor_links, :push_url, :string
    rename_column :codeharbor_links, :oauth2token, :api_key
  end
end
