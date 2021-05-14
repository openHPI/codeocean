# frozen_string_literal: true

class CreateFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :files do |t|
      t.text :content
      t.belongs_to :context, polymorphic: true
      t.belongs_to :file
      t.belongs_to :file_type
      t.boolean :hidden
      t.string :name
      t.boolean :read_only
      t.timestamps
    end
  end
end
