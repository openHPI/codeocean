# frozen_string_literal: true

class DeleteInvalidRunnerReservations < ActiveRecord::Migration[8.0]
  def change
    # Keep the first occurrence of each unique combination of execution_environment_id, contributor_type, and contributor_id.
    # Delete all other duplicates from the `runners` table.

    up_only do
      execute <<-SQL.squish
        WITH numbered_runner_reservations AS (
          SELECT id, execution_environment_id, contributor_type, contributor_id,
            ROW_NUMBER() OVER (
                PARTITION BY execution_environment_id, contributor_type, contributor_id
                ORDER BY created_at
            ) AS row_num
          FROM runners
        )
        DELETE
        FROM runners
        WHERE id IN (
            SELECT id
            FROM numbered_runner_reservations
            WHERE row_num > 1
        );
      SQL
    end

    remove_index :runners, %i[runner_id contributor_id contributor_type], unique: true, if_exists: true
    add_index :runners, %i[execution_environment_id contributor_id contributor_type], unique: true
  end
end
