class RemoveRequestorFromRequestForComments < ActiveRecord::Migration
  def change
    rename_column :request_for_comments, :requestor_user_id, :user_id
  end
end
