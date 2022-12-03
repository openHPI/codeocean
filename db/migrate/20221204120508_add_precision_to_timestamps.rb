# frozen_string_literal: true

class AddPrecisionToTimestamps < ActiveRecord::Migration[7.0]
  def change
    tables = %w[
      anomaly_notifications
      codeharbor_links
      comments
      consumers
      error_template_attributes
      error_templates
      events
      execution_environments
      exercise_collections
      exercises
      exercises_proxy_exercises
      external_users
      file_templates
      file_types
      files
      internal_users
      interventions
      linter_check_runs
      lti_parameters
      proxy_exercises
      remote_evaluation_mappings
      request_for_comments
      searches
      structured_error_attributes
      structured_errors
      study_groups
      submissions
      subscriptions
      tags
      testruns
      tips
      user_exercise_feedbacks
      user_exercise_interventions
      user_proxy_exercise_exercises
    ]

    tables.each do |table|
      change_column table, :created_at, :datetime, precision: 6
      change_column table, :updated_at, :datetime, precision: 6
    end

    change_column :authentication_tokens, :expire_at, :datetime, precision: 6
    change_column :community_solution_locks, :locked_until, :datetime, precision: 6
    change_column :exercises, :submission_deadline, :datetime, precision: 6
    change_column :exercises, :late_submission_deadline, :datetime, precision: 6
    change_column :internal_users, :lock_expires_at, :datetime, precision: 6
    change_column :internal_users, :remember_me_token_expires_at, :datetime, precision: 6
    change_column :internal_users, :reset_password_token_expires_at, :datetime, precision: 6
    change_column :internal_users, :reset_password_email_sent_at, :datetime, precision: 6
    change_column :internal_users, :activation_token_expires_at, :datetime, precision: 6
  end
end
