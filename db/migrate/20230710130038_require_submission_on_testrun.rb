# frozen_string_literal: true

class RequireSubmissionOnTestrun < ActiveRecord::Migration[7.0]
  def change
    change_column_null :testruns, :submission_id, false
    add_foreign_key :testruns, :submissions
  end
end
