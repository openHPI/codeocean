# frozen_string_literal: true

class UnifyLtiParameters < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        # We cannot add a foreign key to a table that has rows that violate the constraint.
        LtiParameter.where(external_users_id: nil)
          .or(LtiParameter.where.not(external_users_id: ExternalUser.select(:id)))
          .or(LtiParameter.where(exercises_id: nil))
          .or(LtiParameter.where.not(exercises_id: Exercise.select(:id)))
          .delete_all

        # For each user/exercise pair, keep the most recent LtiParameter.
        LtiParameter.group(:external_users_id, :exercises_id).having('count(*) > 1').count.each do |ids, count|
          LtiParameter.where(external_users_id: ids.first, exercises_id: ids.second).order(updated_at: :asc).limit(count - 1).delete_all
        end
        change_column :lti_parameters, :id, :bigint
      end

      dir.down do
        change_column :lti_parameters, :id, :integer
      end
    end

    remove_column :lti_parameters, :consumers_id, :bigint

    rename_column :lti_parameters, :external_users_id, :external_user_id
    change_column_null :lti_parameters, :external_user_id, false
    add_foreign_key :lti_parameters, :external_users

    rename_column :lti_parameters, :exercises_id, :exercise_id
    change_column_null :lti_parameters, :exercise_id, false
    add_foreign_key :lti_parameters, :exercises

    add_index :lti_parameters, %i[external_user_id study_group_id exercise_id], unique: true, name: 'index_lti_params_on_external_user_and_study_group_and_exercise'
  end

  class LtiParameter < ActiveRecord::Base; end

  class ExternalUser < ActiveRecord::Base; end

  class Exercise < ActiveRecord::Base; end
end
