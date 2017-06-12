class AddThankYouNoteToRequestForComments < ActiveRecord::Migration
  def change
    add_column :request_for_comments, :thank_you_note, :text
  end
end
