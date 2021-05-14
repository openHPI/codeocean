# frozen_string_literal: true

class CreateErrors < ActiveRecord::Migration[4.2]
  def change
    create_table :errors do |t|
      t.belongs_to :execution_environment
      t.text :message
      t.timestamps
    end
  end
end
