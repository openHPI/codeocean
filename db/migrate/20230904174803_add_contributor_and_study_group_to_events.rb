# frozen_string_literal: true

class AddContributorAndStudyGroupToEvents < ActiveRecord::Migration[7.0]
  def change
    add_reference :events, :programming_group, index: true, null: true, foreign_key: true
    add_reference :events, :study_group, index: true, null: true, foreign_key: true
  end
end
