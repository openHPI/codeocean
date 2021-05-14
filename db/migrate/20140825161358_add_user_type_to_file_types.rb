# frozen_string_literal: true

class AddUserTypeToFileTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :file_types, :user_type, :string
  end
end
