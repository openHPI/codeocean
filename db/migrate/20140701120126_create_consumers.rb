# frozen_string_literal: true

class CreateConsumers < ActiveRecord::Migration[4.2]
  def change
    create_table :consumers do |t|
      t.string :name
      t.timestamps
    end
  end
end
