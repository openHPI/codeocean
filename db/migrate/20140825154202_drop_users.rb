# frozen_string_literal: true

class DropUsers < ActiveRecord::Migration[4.2]
  def change
    drop_table :users
  end
end
