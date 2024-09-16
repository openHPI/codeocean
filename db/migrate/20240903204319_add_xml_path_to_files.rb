# frozen_string_literal: true

class AddXmlPathToFiles < ActiveRecord::Migration[7.1]
  def change
    add_column :files, :xml_id_path, :string, null: true, default: nil
  end
end
