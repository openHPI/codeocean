# frozen_string_literal: true

class AddDetailsToTestruns < ActiveRecord::Migration[6.1]
  def change
    change_table :testruns do |t|
      t.integer :exit_code, limit: 2, null: true, comment: 'No exit code is available in case of a timeout'
      t.check_constraint 'exit_code >= 0 AND exit_code <= 255', name: 'exit_code_constraint'
      t.integer :status, limit: 1, null: false, default: 0, comment: 'Used as enum in Rails'
    end

    enable_extension 'pgcrypto' unless extensions.include?('pgcrypto')

    create_table :testrun_messages, id: :uuid do |t|
      t.belongs_to :testrun, foreign_key: true, null: false, index: true
      t.interval :timestamp, null: false, default: '00:00:00'
      t.integer :cmd, limit: 1, null: false, default: 1, comment: 'Used as enum in Rails'
      t.integer :stream, limit: 1, null: true, comment: 'Used as enum in Rails'
      t.text :log, null: true
      t.jsonb :data, null: true
      t.check_constraint 'log IS NULL OR data IS NULL', name: 'either_data_or_log'
      t.timestamps
    end
  end
end
