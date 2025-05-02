# frozen_string_literal: true

class AddConstraintsToRunner < ActiveRecord::Migration[8.0]
  class ExecutionEnvironment < ApplicationRecord
    has_many :runners
  end

  class Runner < ApplicationRecord
    belongs_to :execution_environment
  end

  def change
    change_column_null :runners, :runner_id, false
    change_column_null :runners, :execution_environment_id, false
    change_column_null :runners, :contributor_id, false
    change_column_null :runners, :contributor_type, false

    add_index :runners, :runner_id, unique: true

    up_only do
      # We cannot add a foreign key to a table that has rows that violate the constraint.
      Runner.where.not(execution_environment_id: ExecutionEnvironment.select(:id)).delete_all
    end
    add_foreign_key :runners, :execution_environments

    add_index :runners, %i[runner_id contributor_id contributor_type], unique: true
  end
end
