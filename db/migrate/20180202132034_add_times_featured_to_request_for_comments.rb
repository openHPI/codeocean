class AddTimesFeaturedToRequestForComments < ActiveRecord::Migration
  def change
    add_column :request_for_comments, :times_featured, :integer, default: 0
  end
end
