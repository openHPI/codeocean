# frozen_string_literal: true

class AddStudyGroupToSubmission < ActiveRecord::Migration[5.2]
  def change
    add_reference :submissions, :study_group, index: true, null: true, foreign_key: true
  end
end
