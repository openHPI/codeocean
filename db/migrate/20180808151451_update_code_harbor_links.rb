class UpdateCodeHarborLinks < ActiveRecord::Migration
  def change
    add_column :code_harbor_links, :client_id, :string
    add_column :code_harbor_links, :client_secret, :string
  end
end
