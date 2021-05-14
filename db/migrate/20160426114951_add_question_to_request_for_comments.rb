# frozen_string_literal: true

class AddQuestionToRequestForComments < ActiveRecord::Migration[4.2]
  def change
    add_column :request_for_comments, :question, :text
  end
end
