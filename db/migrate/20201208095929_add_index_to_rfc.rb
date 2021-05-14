# frozen_string_literal: true

class AddIndexToRfc < ActiveRecord::Migration[5.2]
  def change
    add_index(:request_for_comments, %i[user_id user_type created_at],
      order: {user_id: :asc, user_type: :asc, created_at: :desc}, name: :index_rfc_on_user_and_created_at)
  end
end
