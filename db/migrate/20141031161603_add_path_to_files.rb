# frozen_string_literal: true

class AddPathToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :path, :string
  end
end
