# frozen_string_literal: true

class AddTimesFeaturedToRequestForComments < ActiveRecord::Migration[4.2]
  def change
    add_column :request_for_comments, :times_featured, :integer, default: 0
  end
end
