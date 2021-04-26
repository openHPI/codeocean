# frozen_string_literal: true

class AddStudyGroupToRemoteEvaluationMapping < ActiveRecord::Migration[5.2]
  def change
    add_reference :remote_evaluation_mappings, :study_group, index: true, null: true, foreign_key: true
  end
end
