# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_03_20_220012) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "anomaly_notifications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.integer "exercise_id"
    t.integer "exercise_collection_id"
    t.string "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["exercise_collection_id"], name: "index_anomaly_notifications_on_exercise_collection_id"
    t.index ["exercise_id"], name: "index_anomaly_notifications_on_exercise_id"
    t.index ["user_type", "user_id"], name: "index_anomaly_notifications_on_user"
  end

  create_table "authentication_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "shared_secret", null: false
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.datetime "expire_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "study_group_id"
    t.index ["shared_secret"], name: "index_authentication_tokens_on_shared_secret", unique: true
    t.index ["study_group_id"], name: "index_authentication_tokens_on_study_group_id"
    t.index ["user_type", "user_id"], name: "index_authentication_tokens_on_user"
  end

  create_table "codeharbor_links", id: :serial, force: :cascade do |t|
    t.string "api_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "push_url"
    t.string "check_uuid_url"
    t.string "user_type"
    t.index ["user_type", "user_id"], name: "index_codeharbor_links_on_user_type_and_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "file_id"
    t.string "user_type"
    t.integer "row"
    t.integer "column"
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["file_id"], name: "index_comments_on_file_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "community_solution_contributions", force: :cascade do |t|
    t.bigint "community_solution_id", null: false
    t.bigint "study_group_id"
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.bigint "community_solution_lock_id", null: false
    t.boolean "proposed_changes", null: false
    t.boolean "timely_contribution", null: false
    t.boolean "autosave", null: false
    t.interval "working_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_solution_id", "timely_contribution", "autosave", "proposed_changes"], name: "index_community_solution_valid_contributions"
    t.index ["community_solution_lock_id"], name: "index_community_solution_contributions_lock"
    t.index ["user_type", "user_id"], name: "index_community_solution_contributions_on_user"
  end

  create_table "community_solution_locks", force: :cascade do |t|
    t.bigint "community_solution_id", null: false
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.datetime "locked_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_solution_id", "locked_until"], name: "index_community_solution_locks_until", unique: true
    t.index ["user_type", "user_id"], name: "index_community_solution_locks_on_user"
  end

  create_table "community_solutions", force: :cascade do |t|
    t.bigint "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_community_solutions_on_exercise_id"
  end

  create_table "consumers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "oauth_key"
    t.string "oauth_secret"
    t.integer "rfc_visibility", limit: 2, default: 0, null: false, comment: "Used as enum in Rails"
  end

  create_table "error_template_attributes", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "regex"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.boolean "important"
  end

  create_table "error_template_attributes_templates", id: false, force: :cascade do |t|
    t.integer "error_template_id", null: false
    t.integer "error_template_attribute_id", null: false
  end

  create_table "error_templates", id: :serial, force: :cascade do |t|
    t.integer "execution_environment_id"
    t.string "name"
    t.string "signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.text "hint"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "category"
    t.string "data"
    t.integer "user_id"
    t.string "user_type"
    t.integer "exercise_id"
    t.integer "file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "execution_environments", id: :serial, force: :cascade do |t|
    t.string "docker_image"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "run_command"
    t.string "test_command"
    t.string "testing_framework"
    t.text "help"
    t.integer "permitted_execution_time"
    t.integer "user_id"
    t.string "user_type"
    t.integer "pool_size"
    t.integer "file_type_id"
    t.integer "memory_limit"
    t.boolean "network_enabled"
    t.integer "cpu_limit", default: 20, null: false
    t.integer "exposed_ports", default: [], array: true
    t.boolean "privileged_execution", default: false, null: false
  end

  create_table "exercise_collection_items", id: :serial, force: :cascade do |t|
    t.integer "exercise_collection_id"
    t.integer "exercise_id"
    t.integer "position", default: 0, null: false
    t.index ["exercise_collection_id"], name: "index_exercise_collection_items_on_exercise_collection_id"
    t.index ["exercise_id"], name: "index_exercise_collection_items_on_exercise_id"
  end

  create_table "exercise_collections", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "use_anomaly_detection", default: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_type", "user_id"], name: "index_exercise_collections_on_user_type_and_user_id"
  end

  create_table "exercise_tags", id: :serial, force: :cascade do |t|
    t.integer "exercise_id"
    t.integer "tag_id"
    t.integer "factor", default: 1
  end

  create_table "exercise_tips", force: :cascade do |t|
    t.bigint "exercise_id", null: false
    t.bigint "tip_id", null: false
    t.integer "rank", null: false
    t.bigint "parent_exercise_tip_id"
    t.index ["exercise_id", "rank"], name: "index_exercise_tips_on_exercise_id_and_rank"
    t.index ["exercise_id"], name: "index_exercise_tips_on_exercise_id"
    t.index ["parent_exercise_tip_id"], name: "index_exercise_tips_on_parent_exercise_tip_id"
    t.index ["tip_id"], name: "index_exercise_tips_on_tip_id"
  end

  create_table "exercises", id: :serial, force: :cascade do |t|
    t.text "description"
    t.integer "execution_environment_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.text "instructions"
    t.boolean "public"
    t.string "user_type"
    t.string "token"
    t.boolean "hide_file_tree"
    t.boolean "allow_file_creation"
    t.boolean "allow_auto_completion", default: false
    t.integer "expected_difficulty", default: 1
    t.uuid "uuid"
    t.boolean "unpublished", default: false
    t.datetime "submission_deadline"
    t.datetime "late_submission_deadline"
    t.index ["id"], name: "index_exercises_on_id"
    t.index ["id"], name: "index_unpublished_exercises", where: "(NOT unpublished)"
    t.index ["title"], name: "index_exercises_on_title", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "exercises_proxy_exercises", id: false, force: :cascade do |t|
    t.integer "proxy_exercise_id"
    t.integer "exercise_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["exercise_id"], name: "index_exercises_proxy_exercises_on_exercise_id"
    t.index ["proxy_exercise_id"], name: "index_exercises_proxy_exercises_on_proxy_exercise_id"
  end

  create_table "external_users", id: :serial, force: :cascade do |t|
    t.integer "consumer_id"
    t.string "email"
    t.string "external_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "platform_admin", default: false, null: false
  end

  create_table "file_templates", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "content"
    t.integer "file_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "file_types", id: :serial, force: :cascade do |t|
    t.string "editor_mode"
    t.string "file_extension"
    t.integer "indent_size"
    t.string "name"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "executable"
    t.boolean "renderable"
    t.string "user_type"
    t.boolean "binary"
  end

  create_table "files", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "context_id"
    t.string "context_type"
    t.integer "file_id"
    t.integer "file_type_id"
    t.boolean "hidden"
    t.string "name"
    t.boolean "read_only"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "native_file"
    t.string "role"
    t.string "hashed_content"
    t.string "feedback_message"
    t.float "weight"
    t.string "path"
    t.integer "file_template_id"
    t.index ["context_id", "context_type"], name: "index_files_on_context_id_and_context_type"
  end

  create_table "internal_users", id: :serial, force: :cascade do |t|
    t.integer "consumer_id"
    t.string "email"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "crypted_password"
    t.string "salt"
    t.integer "failed_logins_count", default: 0
    t.datetime "lock_expires_at"
    t.string "unlock_token"
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string "activation_state"
    t.string "activation_token"
    t.datetime "activation_token_expires_at"
    t.boolean "platform_admin", default: false, null: false
    t.index ["activation_token"], name: "index_internal_users_on_activation_token"
    t.index ["email"], name: "index_internal_users_on_email", unique: true
    t.index ["remember_me_token"], name: "index_internal_users_on_remember_me_token"
    t.index ["reset_password_token"], name: "index_internal_users_on_reset_password_token"
  end

  create_table "interventions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "markup"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "linter_check_runs", force: :cascade do |t|
    t.bigint "linter_check_id", null: false
    t.string "scope"
    t.integer "line"
    t.text "result"
    t.bigint "testrun_id", null: false
    t.bigint "file_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_id"], name: "index_linter_check_runs_on_file_id"
    t.index ["linter_check_id"], name: "index_linter_check_runs_on_linter_check_id"
    t.index ["testrun_id"], name: "index_linter_check_runs_on_testrun_id"
  end

  create_table "linter_checks", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "severity"
  end

  create_table "lti_parameters", id: :serial, force: :cascade do |t|
    t.integer "external_users_id"
    t.integer "consumers_id"
    t.integer "exercises_id"
    t.jsonb "lti_parameters", default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["external_users_id"], name: "index_lti_parameters_on_external_users_id"
  end

  create_table "proxy_exercises", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.bigint "user_id"
    t.boolean "public", default: false, null: false
    t.integer "algorithm", limit: 2, default: 0, null: false, comment: "Used as enum in Rails"
    t.index ["user_type", "user_id"], name: "index_proxy_exercises_on_user_type_and_user_id"
  end

  create_table "remote_evaluation_mappings", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "exercise_id", null: false
    t.string "validation_token", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.bigint "study_group_id"
    t.index ["study_group_id"], name: "index_remote_evaluation_mappings_on_study_group_id"
  end

  create_table "request_for_comments", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "exercise_id", null: false
    t.integer "file_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.text "question"
    t.boolean "solved", default: false
    t.integer "submission_id"
    t.text "thank_you_note"
    t.boolean "full_score_reached", default: false
    t.integer "times_featured", default: 0
    t.index ["exercise_id", "created_at"], name: "index_unresolved_recommended_rfcs", where: "(((NOT solved) OR (solved IS NULL)) AND ((question IS NOT NULL) AND (question <> ''::text)))"
    t.index ["exercise_id"], name: "index_request_for_comments_on_exercise_id"
    t.index ["submission_id"], name: "index_request_for_comments_on_submission_id"
    t.index ["user_id", "user_type", "created_at"], name: "index_rfc_on_user_and_created_at", order: { created_at: :desc }
  end

  create_table "runners", force: :cascade do |t|
    t.string "runner_id"
    t.bigint "execution_environment_id"
    t.string "user_type"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_environment_id"], name: "index_runners_on_execution_environment_id"
    t.index ["user_type", "user_id"], name: "index_runners_on_user"
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.integer "exercise_id", null: false
    t.integer "user_id", null: false
    t.string "user_type", null: false
    t.string "search"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "structured_error_attributes", id: :serial, force: :cascade do |t|
    t.integer "structured_error_id"
    t.integer "error_template_attribute_id"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "match"
    t.index ["structured_error_id"], name: "index_structured_error_attributes_on_structured_error_id"
  end

  create_table "structured_errors", id: :serial, force: :cascade do |t|
    t.integer "error_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "submission_id"
    t.index ["submission_id"], name: "index_structured_errors_on_submission_id"
  end

  create_table "study_group_memberships", force: :cascade do |t|
    t.bigint "study_group_id"
    t.string "user_type"
    t.bigint "user_id"
    t.integer "role", limit: 2, default: 0, null: false, comment: "Used as enum in Rails"
    t.index ["study_group_id"], name: "index_study_group_memberships_on_study_group_id"
    t.index ["user_type", "user_id"], name: "index_study_group_memberships_on_user"
  end

  create_table "study_groups", force: :cascade do |t|
    t.string "name"
    t.string "external_id"
    t.bigint "consumer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consumer_id"], name: "index_study_groups_on_consumer_id"
    t.index ["external_id", "consumer_id"], name: "index_study_groups_on_external_id_and_consumer_id", unique: true
  end

  create_table "submissions", id: :serial, force: :cascade do |t|
    t.integer "exercise_id"
    t.float "score"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cause"
    t.string "user_type"
    t.bigint "study_group_id"
    t.index ["exercise_id"], name: "index_submissions_on_exercise_id"
    t.index ["study_group_id"], name: "index_submissions_on_study_group_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.integer "request_for_comment_id"
    t.string "subscription_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deleted"
    t.bigint "study_group_id"
    t.index ["study_group_id"], name: "index_subscriptions_on_study_group_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "testrun_execution_environments", force: :cascade do |t|
    t.bigint "testrun_id", null: false
    t.bigint "execution_environment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["execution_environment_id"], name: "index_testrun_execution_environments"
    t.index ["testrun_id"], name: "index_testrun_execution_environments_on_testrun_id"
  end

  create_table "testrun_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "testrun_id", null: false
    t.interval "timestamp", default: "PT0S", null: false
    t.integer "cmd", limit: 2, default: 1, null: false, comment: "Used as enum in Rails"
    t.integer "stream", limit: 2, comment: "Used as enum in Rails"
    t.text "log"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["testrun_id"], name: "index_testrun_messages_on_testrun_id"
    t.check_constraint "log IS NULL OR data IS NULL", name: "either_data_or_log"
  end

  create_table "testruns", id: :serial, force: :cascade do |t|
    t.boolean "passed"
    t.text "output"
    t.integer "file_id"
    t.integer "submission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cause"
    t.interval "container_execution_time"
    t.interval "waiting_for_container_time"
    t.integer "exit_code", limit: 2, comment: "No exit code is available in case of a timeout"
    t.integer "status", limit: 2, default: 0, null: false, comment: "Used as enum in Rails"
    t.index ["submission_id"], name: "index_testruns_on_submission_id"
    t.check_constraint "exit_code >= 0 AND exit_code <= 255", name: "exit_code_constraint"
  end

  create_table "tips", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "example"
    t.bigint "file_type_id"
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_type_id"], name: "index_tips_on_file_type_id"
    t.index ["user_type", "user_id"], name: "index_tips_on_user"
  end

  create_table "user_exercise_feedbacks", id: :serial, force: :cascade do |t|
    t.integer "exercise_id", null: false
    t.integer "user_id", null: false
    t.string "user_type", null: false
    t.integer "difficulty"
    t.integer "working_time_seconds"
    t.string "feedback_text"
    t.integer "user_estimated_worktime"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "normalized_score"
    t.bigint "submission_id"
    t.index ["submission_id"], name: "index_user_exercise_feedbacks_on_submission_id"
  end

  create_table "user_exercise_interventions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.integer "exercise_id"
    t.integer "intervention_id"
    t.integer "accumulated_worktime_s"
    t.text "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_proxy_exercise_exercises", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.integer "proxy_exercise_id"
    t.integer "exercise_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reason"
    t.index ["exercise_id"], name: "index_user_proxy_exercise_exercises_on_exercise_id"
    t.index ["proxy_exercise_id"], name: "index_user_proxy_exercise_exercises_on_proxy_exercise_id"
    t.index ["user_type", "user_id"], name: "index_user_proxy_exercise_exercises_on_user"
  end

  create_table "wk2020_until_rfc_reply", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "exercise_id"
    t.interval "working_time_until_rfc_reply"
  end

  create_table "wk2020_with_wk_until_rfc", id: false, force: :cascade do |t|
    t.string "external_user_id", limit: 255
    t.integer "user_id"
    t.integer "exercise_id"
    t.float "max_score"
    t.float "max_reachable_points"
    t.interval "working_time"
    t.interval "working_time_until_rfc"
    t.interval "working_time_until_rfc_reply"
    t.time "percentile75"
    t.time "percentile90"
  end

  add_foreign_key "authentication_tokens", "study_groups"
  add_foreign_key "community_solution_contributions", "community_solution_locks"
  add_foreign_key "community_solution_contributions", "community_solutions"
  add_foreign_key "community_solution_contributions", "study_groups"
  add_foreign_key "community_solution_locks", "community_solutions"
  add_foreign_key "community_solutions", "exercises"
  add_foreign_key "exercise_tips", "exercise_tips", column: "parent_exercise_tip_id"
  add_foreign_key "exercise_tips", "exercises"
  add_foreign_key "exercise_tips", "tips"
  add_foreign_key "remote_evaluation_mappings", "study_groups"
  add_foreign_key "structured_error_attributes", "error_template_attributes"
  add_foreign_key "structured_error_attributes", "structured_errors"
  add_foreign_key "structured_errors", "error_templates"
  add_foreign_key "structured_errors", "error_templates", name: "structured_errors_error_templates_id_fk"
  add_foreign_key "structured_errors", "submissions"
  add_foreign_key "submissions", "study_groups"
  add_foreign_key "subscriptions", "study_groups"
  add_foreign_key "testrun_execution_environments", "execution_environments"
  add_foreign_key "testrun_execution_environments", "testruns"
  add_foreign_key "testrun_messages", "testruns"
  add_foreign_key "tips", "file_types"
  add_foreign_key "user_exercise_feedbacks", "submissions"
end
