# frozen_string_literal: true

class AddStudyGroupToLtiParameters < ActiveRecord::Migration[7.0]
  def change
    add_reference :lti_parameters, :study_group, index: true, null: true, foreign_key: true
  end
end
