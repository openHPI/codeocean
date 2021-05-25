# frozen_string_literal: true

class CreateRunners < ActiveRecord::Migration[6.1]
  def change
    create_table :runners do |t|
      t.string :runner_id
      t.references :execution_environment
      t.references :user, polymorphic: true
      t.float :waiting_time

      t.timestamps
    end
  end
end
