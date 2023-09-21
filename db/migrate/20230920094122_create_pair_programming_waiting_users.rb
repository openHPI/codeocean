# frozen_string_literal: true

class CreatePairProgrammingWaitingUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :pair_programming_waiting_users, id: :uuid do |t|
      t.references :user, index: true, null: false, polymorphic: true
      t.references :exercise, index: true, null: false, foreign_key: true
      t.references :programming_group, index: true, null: true, foreign_key: true
      t.integer :status, limit: 1, null: false, comment: 'Used as enum in Rails'

      t.timestamps
    end
  end
end
