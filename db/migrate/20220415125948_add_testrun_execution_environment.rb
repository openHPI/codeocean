# frozen_string_literal: true

class AddTestrunExecutionEnvironment < ActiveRecord::Migration[6.1]
  def change
    create_table :testrun_execution_environments do |t|
      t.belongs_to :testrun, foreign_key: true, null: false, index: true
      t.belongs_to :execution_environment, foreign_key: true, null: false, index: {name: 'index_testrun_execution_environments'}

      t.timestamps
    end
  end
end
