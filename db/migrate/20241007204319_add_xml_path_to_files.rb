# frozen_string_literal: true

class AddXmlPathToFiles < ActiveRecord::Migration[7.1]
  def change
    add_column :files, :xml_id_path, :string, array: true, default: [], null: true
  end
end
