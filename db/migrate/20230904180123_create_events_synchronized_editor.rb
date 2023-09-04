# frozen_string_literal: true

class CreateEventsSynchronizedEditor < ActiveRecord::Migration[7.0]
  def change
    create_table :events_synchronized_editor, id: :uuid do |t|
      t.references :programming_group, index: true, null: false, foreign_key: true
      t.references :study_group, index: true, null: false, foreign_key: true
      t.references :user, index: true, null: false, polymorphic: true
      t.integer :command, limit: 1, null: false, default: 0, comment: 'Used as enum in Rails'
      t.integer :status, limit: 1, null: true, comment: 'Used as enum in Rails'

      # The following attributes are only stored for delta objects
      t.references :file, index: true, null: true, foreign_key: true
      t.integer :action, limit: 1, null: true, comment: 'Used as enum in Rails'
      t.integer :range_start_row, null: true
      t.integer :range_start_column, null: true
      t.integer :range_end_row, null: true
      t.integer :range_end_column, null: true
      t.text :text, null: true
      t.text :lines, null: true, array: true
      t.string :nl, limit: 2, null: true, comment: 'Identifies the line break type (i.e., \r\n or \n)'
      t.jsonb :data, null: true

      t.timestamps
    end
  end
end
