# frozen_string_literal: true

class RemoveRequestorFromRequestForComments < ActiveRecord::Migration[4.2]
  def change
    rename_column :request_for_comments, :requestor_user_id, :user_id
  end
end
