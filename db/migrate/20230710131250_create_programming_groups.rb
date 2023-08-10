# frozen_string_literal: true

class CreateProgrammingGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :programming_groups do |t|
      t.belongs_to :exercise, foreign_key: true, null: false, index: true

      t.timestamps
    end
  end
end
