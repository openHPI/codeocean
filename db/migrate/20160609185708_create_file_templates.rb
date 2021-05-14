# frozen_string_literal: true

class CreateFileTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :file_templates do |t|
      t.string :name
      t.text :content
      t.belongs_to :file_type
      t.timestamps
    end
  end
end
