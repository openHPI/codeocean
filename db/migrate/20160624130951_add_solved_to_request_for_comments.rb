# frozen_string_literal: true

class AddSolvedToRequestForComments < ActiveRecord::Migration[4.2]
  def change
    add_column :request_for_comments, :solved, :boolean
  end
end
