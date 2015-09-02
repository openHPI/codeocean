class AddUserTypeToRequestForComments < ActiveRecord::Migration
  def change
    add_column :request_for_comments, :user_type, :string
  end
end
