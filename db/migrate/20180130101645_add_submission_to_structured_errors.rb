class AddSubmissionToStructuredErrors < ActiveRecord::Migration
  def change
    add_reference :structured_errors, :submission, index: true
  end
end
