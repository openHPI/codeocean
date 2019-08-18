class AddPushUrlClientIdClientSecretToCodeharborLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :codeharbor_links, :push_url, :string
    add_column :codeharbor_links, :client_id, :string
    add_column :codeharbor_links, :client_secret, :string
  end
end
