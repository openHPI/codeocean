# frozen_string_literal: true

class CreateErrorTemplateAttributes < ActiveRecord::Migration[4.2]
  def change
    create_table :error_template_attributes do |t|
      t.belongs_to :error_template
      t.string :key
      t.string :regex

      t.timestamps null: false
    end
  end
end
