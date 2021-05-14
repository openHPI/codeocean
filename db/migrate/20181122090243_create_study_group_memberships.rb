# frozen_string_literal: true

class CreateStudyGroupMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :study_group_memberships do |t|
      t.belongs_to :study_group
      t.belongs_to :user, polymorphic: true
    end
  end
end
