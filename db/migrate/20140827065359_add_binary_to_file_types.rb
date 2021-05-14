# frozen_string_literal: true

class AddBinaryToFileTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :file_types, :binary, :boolean
  end
end
