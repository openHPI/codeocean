# frozen_string_literal: true

class AddUserToCodeHarborLink < ActiveRecord::Migration[4.2]
  def change
    add_reference :code_harbor_links, :user, polymorphic: true, index: true
  end
end
