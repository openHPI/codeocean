# frozen_string_literal: true

class AddProgrammingGroupToRemoteEvalutionMapping < ActiveRecord::Migration[7.1]
  def change
    add_reference :remote_evaluation_mappings, :programming_group, index: true, null: true, foreign_key: true
  end
end
