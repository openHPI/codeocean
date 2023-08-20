# frozen_string_literal: true

class RequireContributorOnSubmission < ActiveRecord::Migration[7.0]
  def change
    change_column_null :submissions, :contributor_id, false
    change_column_null :submissions, :contributor_type, false
  end
end
