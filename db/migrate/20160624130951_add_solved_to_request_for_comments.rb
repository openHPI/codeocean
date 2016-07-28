class AddSolvedToRequestForComments < ActiveRecord::Migration
  def change
    add_column :request_for_comments, :solved, :boolean
  end
end
