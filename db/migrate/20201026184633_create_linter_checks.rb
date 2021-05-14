# frozen_string_literal: true

class CreateLinterChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :linter_checks do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :severity
    end

    create_table :linter_check_runs do |t|
      t.references :linter_check, null: false
      t.string :scope
      t.integer :line
      t.text :result
      t.references :testrun, null: false
      t.references :file, null: false
      t.timestamps
    end
  end
end
