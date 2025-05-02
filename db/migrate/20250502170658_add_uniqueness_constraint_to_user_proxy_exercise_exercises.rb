# frozen_string_literal: true

class AddUniquenessConstraintToUserProxyExerciseExercises < ActiveRecord::Migration[8.0]
  class UserProxyExerciseExercise < ApplicationRecord
  end

  def change
    change_column_null :user_proxy_exercise_exercises, :user_id, false
    change_column_null :user_proxy_exercise_exercises, :user_type, false
    change_column_null :user_proxy_exercise_exercises, :proxy_exercise_id, false
    change_column_null :user_proxy_exercise_exercises, :exercise_id, false

    add_foreign_key :user_proxy_exercise_exercises, :proxy_exercises
    add_foreign_key :user_proxy_exercise_exercises, :exercises

    up_only do
      # We cannot add a unique index to a table that has duplicate rows.
      # Hence, we keep the oldest row(s) and remove the others.
      execute <<~SQL.squish
        WITH duplicates AS (SELECT
            dense_rank() over (PARTITION BY a.user_id, a.user_type, a.proxy_exercise_id, a.exercise_id ORDER BY a.created_at) AS row,
            a.id AS upee_id
          FROM user_proxy_exercise_exercises a
          JOIN user_proxy_exercise_exercises b
            ON a.user_id = b.user_id
           AND a.user_type = b.user_type
           AND a.proxy_exercise_id = b.proxy_exercise_id
           AND a.exercise_id = b.exercise_id
           AND a.id != b.id
          ORDER BY a.created_at)
        DELETE FROM user_proxy_exercise_exercises
        WHERE id IN (SELECT upee_id FROM duplicates WHERE row != 1)
      SQL
    end

    add_index :user_proxy_exercise_exercises, %i[user_id user_type proxy_exercise_id], unique: true
  end
end
