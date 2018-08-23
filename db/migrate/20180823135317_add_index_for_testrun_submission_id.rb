class AddIndexForTestrunSubmissionId < ActiveRecord::Migration
  def change
    add_index :testruns, :submission_id
  end
end
