class RemoveRequestedAtFromRequestForComments < ActiveRecord::Migration
  def change
    remove_column :request_for_comments, :requested_at
  end
end
