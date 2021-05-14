# frozen_string_literal: true

class AddIndicesForRequestForComments < ActiveRecord::Migration[5.2]
  def change
    add_index :request_for_comments, :submission_id
    add_index :request_for_comments, :exercise_id
  end
end
