# frozen_string_literal: true

class AddUserTypeToRequestForComments < ActiveRecord::Migration[4.2]
  def change
    add_column :request_for_comments, :user_type, :string
  end
end
