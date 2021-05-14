# frozen_string_literal: true

class RemoveRequestedAtFromRequestForComments < ActiveRecord::Migration[4.2]
  def change
    remove_column :request_for_comments, :requested_at
  end
end
