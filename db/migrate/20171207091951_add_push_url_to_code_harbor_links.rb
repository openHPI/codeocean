class AddPushUrlToCodeHarborLinks < ActiveRecord::Migration
  def change
    add_column :code_harbor_links, :push_url, :string
  end
end
