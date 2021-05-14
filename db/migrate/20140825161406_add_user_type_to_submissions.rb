# frozen_string_literal: true

class AddUserTypeToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :user_type, :string
  end
end
