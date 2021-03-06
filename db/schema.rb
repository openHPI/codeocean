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

ActiveRecord::Schema.define(version: 2021_05_12_133612) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
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
    t.index ["user_type", "user_id"], name: "index_anomaly_notifications_on_user_type_and_user_id"
  end

  create_table "codeharbor_links", id: :serial, force: :cascade do |t|
    t.string "api_key", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "push_url"
    t.string "check_uuid_url"
    t.index ["user_id"], name: "index_codeharbor_links_on_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "file_id"
    t.string "user_type", limit: 255
    t.integer "row"
    t.integer "column"
    t.text "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["file_id"], name: "index_comments_on_file_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "consumers", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "oauth_key", limit: 255
    t.string "oauth_secret", limit: 255
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
    t.string "docker_image", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "run_command", limit: 255
    t.string "test_command", limit: 255
    t.string "testing_framework", limit: 255
    t.text "help"
    t.string "exposed_ports", limit: 255
    t.integer "permitted_execution_time"
    t.integer "user_id"
    t.string "user_type", limit: 255
    t.integer "pool_size"
    t.integer "file_type_id"
    t.integer "memory_limit"
    t.boolean "network_enabled"
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
    t.string "title", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.text "instructions"
    t.boolean "public"
    t.string "user_type", limit: 255
    t.string "token", limit: 255
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
    t.string "email", limit: 255
    t.string "external_id", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "role", default: "learner", null: false
  end

  create_table "file_templates", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "content"
    t.integer "file_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "file_types", id: :serial, force: :cascade do |t|
    t.string "editor_mode", limit: 255
    t.string "file_extension", limit: 255
    t.integer "indent_size"
    t.string "name", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "executable"
    t.boolean "renderable"
    t.string "user_type", limit: 255
    t.boolean "binary"
  end

  create_table "files", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "context_id"
    t.string "context_type", limit: 255
    t.integer "file_id"
    t.integer "file_type_id"
    t.boolean "hidden"
    t.string "name", limit: 255
    t.boolean "read_only"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "native_file", limit: 255
    t.string "role", limit: 255
    t.string "hashed_content", limit: 255
    t.string "feedback_message", limit: 255
    t.float "weight"
    t.string "path", limit: 255
    t.integer "file_template_id"
    t.index ["context_id", "context_type"], name: "index_files_on_context_id_and_context_type"
  end

  create_table "internal_users", id: :serial, force: :cascade do |t|
    t.integer "consumer_id"
    t.string "email", limit: 255
    t.string "name", limit: 255
    t.string "role", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "crypted_password", limit: 255
    t.string "salt", limit: 255
    t.integer "failed_logins_count", default: 0
    t.datetime "lock_expires_at"
    t.string "unlock_token", limit: 255
    t.string "remember_me_token", limit: 255
    t.datetime "remember_me_token_expires_at"
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string "activation_state", limit: 255
    t.string "activation_token", limit: 255
    t.datetime "activation_token_expires_at"
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
    t.string "user_type", limit: 255
    t.text "question"
    t.boolean "solved", default: false
    t.integer "submission_id"
    t.text "thank_you_note"
    t.boolean "full_score_reached", default: false
    t.integer "times_featured", default: 0
    t.index ["exercise_id"], name: "index_request_for_comments_on_exercise_id"
    t.index ["submission_id"], name: "index_request_for_comments_on_submission_id"
    t.index ["user_id", "user_type", "created_at"], name: "index_rfc_on_user_and_created_at", order: { created_at: :desc }
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
    t.index ["study_group_id"], name: "index_study_group_memberships_on_study_group_id"
    t.index ["user_type", "user_id"], name: "index_study_group_memberships_on_user_type_and_user_id"
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
    t.string "cause", limit: 255
    t.string "user_type", limit: 255
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
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.index ["submission_id"], name: "index_testruns_on_submission_id"
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
    t.index ["user_type", "user_id"], name: "index_tips_on_user_type_and_user_id"
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
    t.index ["user_type", "user_id"], name: "index_user_proxy_exercise_exercises_on_user_type_and_user_id"
  end

  add_foreign_key "exercise_tips", "exercise_tips", column: "parent_exercise_tip_id"
  add_foreign_key "exercise_tips", "exercises"
  add_foreign_key "exercise_tips", "tips"
  add_foreign_key "remote_evaluation_mappings", "study_groups"
  add_foreign_key "submissions", "study_groups"
  add_foreign_key "tips", "file_types"
  add_foreign_key "user_exercise_feedbacks", "submissions"
end
