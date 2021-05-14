# frozen_string_literal: true

class RenameCodeHarborLinksToCodeharborLinks < ActiveRecord::Migration[5.2]
  def change
    rename_table :code_harbor_links, :codeharbor_links
  end
end
