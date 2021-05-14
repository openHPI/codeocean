# frozen_string_literal: true

class AddNativeFileToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :native_file, :string
  end
end
