class AddUserToCodeHarborLink < ActiveRecord::Migration
  def change
    add_reference :code_harbor_links, :user,  polymorphic: true, index: true
  end
end
