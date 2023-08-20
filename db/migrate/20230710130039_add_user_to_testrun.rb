# frozen_string_literal: true

class AddUserToTestrun < ActiveRecord::Migration[7.0]
  def change
    add_reference :testruns, :user, polymorphic: true, index: true

    up_only do
      # Since we do not have programming groups, we can assume that the user who triggered a testrun is the same as the author of the corresponding submission.
      # For programming groups, this assumption is not valid (the author of a submission would the group, whereas an individual user would trigger the testrun).
      execute <<~SQL.squish
        UPDATE testruns
        SET user_id   = submissions.contributor_id,
            user_type = submissions.contributor_type
        FROM submissions
        WHERE submissions.id = testruns.submission_id;
      SQL
    end

    change_column_null :testruns, :user_id, false
    change_column_null :testruns, :user_type, false
  end
end
