# frozen_string_literal: true

class CreateErrorTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :error_templates do |t|
      t.belongs_to :execution_environment
      t.string :name
      t.string :signature

      t.timestamps null: false
    end
  end
end
