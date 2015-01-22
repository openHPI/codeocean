class AddUserTypeToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :user_type, :string
  end
end
