# frozen_string_literal: true

class AddIndexForTestrunSubmissionId < ActiveRecord::Migration[4.2]
  def change
    add_index :testruns, :submission_id
  end
end
