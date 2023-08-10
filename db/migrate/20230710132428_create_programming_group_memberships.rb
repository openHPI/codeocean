# frozen_string_literal: true

class CreateProgrammingGroupMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :programming_group_memberships, id: :uuid do |t|
      t.belongs_to :programming_group, foreign_key: true, null: false, index: true
      t.belongs_to :user, polymorphic: true, null: false, index: true

      t.timestamps
    end
  end
end
