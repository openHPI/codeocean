# frozen_string_literal: true

class ChangeUniquenessConstraintForStudyGroupExternalId < ActiveRecord::Migration[8.0]
  def change
    remove_index :study_groups, column: %i[external_id consumer_id], unique: true
    add_index :study_groups, %i[external_id consumer_id], unique: true, nulls_not_distinct: true
  end
end
