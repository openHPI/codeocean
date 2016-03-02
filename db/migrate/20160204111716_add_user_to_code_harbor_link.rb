class AddUserToCodeHarborLink < ActiveRecord::Migration
  def change
    add_reference :code_harbor_links, :user, index: true, foreign_key: true
  end
end
