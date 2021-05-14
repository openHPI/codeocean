# frozen_string_literal: true

class AddThankYouNoteToRequestForComments < ActiveRecord::Migration[4.2]
  def change
    add_column :request_for_comments, :thank_you_note, :text
  end
end
