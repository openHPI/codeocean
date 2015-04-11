class AddSubmissionToError < ActiveRecord::Migration
  def change
    add_reference :errors, :submission, index: true
  end
end
