# frozen_string_literal: true

class AddIndexToUserExerciseInterventions < ActiveRecord::Migration[7.1]
  def change
    up_only do
      # We cannot add a foreign key to a table that has rows that violate the constraint.
      UserExerciseIntervention.where.not(exercise_id: Exercise.select(:id)).delete_all
      UserExerciseIntervention.where.not(intervention_id: Intervention.select(:id)).delete_all
    end

    rename_column :user_exercise_interventions, :user_id, :contributor_id
    rename_column :user_exercise_interventions, :user_type, :contributor_type

    change_column_null :user_exercise_interventions, :contributor_type, false
    change_column_null :user_exercise_interventions, :contributor_id, false
    add_index :user_exercise_interventions, %i[contributor_type contributor_id]

    change_column_null :user_exercise_interventions, :exercise_id, false
    add_index :user_exercise_interventions, :exercise_id
    add_foreign_key :user_exercise_interventions, :exercises

    change_column_null :user_exercise_interventions, :intervention_id, false
    add_index :user_exercise_interventions, :intervention_id
    add_foreign_key :user_exercise_interventions, :interventions
  end

  class Exercise < ActiveRecord::Base; end
  class Intervention < ActiveRecord::Base; end
  class UserExerciseIntervention < ActiveRecord::Base; end
end
