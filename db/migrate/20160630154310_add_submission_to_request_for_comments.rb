class AddSubmissionToRequestForComments < ActiveRecord::Migration
  def change
    add_reference :request_for_comments, :submission
  end
end
