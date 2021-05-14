# frozen_string_literal: true

class AddExecutableToFileTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :file_types, :executable, :boolean
  end
end
