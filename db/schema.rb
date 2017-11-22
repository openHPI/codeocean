# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171120153705) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "code_harbor_links", force: :cascade do |t|
    t.string   "oauth2token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "code_harbor_links", ["user_id"], name: "index_code_harbor_links_on_user_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "file_id"
    t.string   "user_type",  limit: 255
    t.integer  "row"
    t.integer  "column"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["file_id"], name: "index_comments_on_file_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "consumers", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "oauth_key",    limit: 255
    t.string   "oauth_secret", limit: 255
  end

  create_table "error_template_attributes", force: :cascade do |t|
    t.string   "key"
    t.string   "regex"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "description"
    t.boolean  "important"
  end

  create_table "error_template_attributes_templates", id: false, force: :cascade do |t|
    t.integer "error_template_id",           null: false
    t.integer "error_template_attribute_id", null: false
  end

  create_table "error_templates", force: :cascade do |t|
    t.integer  "execution_environment_id"
    t.string   "name"
    t.string   "signature"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.text     "description"
    t.text     "hint"
  end

  create_table "errors", force: :cascade do |t|
    t.integer  "execution_environment_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submission_id"
  end

  add_index "errors", ["submission_id"], name: "index_errors_on_submission_id", using: :btree

  create_table "execution_environments", force: :cascade do |t|
    t.string   "docker_image",             limit: 255
    t.string   "name",                     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "run_command",              limit: 255
    t.string   "test_command",             limit: 255
    t.string   "testing_framework",        limit: 255
    t.text     "help"
    t.string   "exposed_ports",            limit: 255
    t.integer  "permitted_execution_time"
    t.integer  "user_id"
    t.string   "user_type",                limit: 255
    t.integer  "pool_size"
    t.integer  "file_type_id"
    t.integer  "memory_limit"
    t.boolean  "network_enabled"
  end

  create_table "exercise_collections", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exercise_collections_exercises", id: false, force: :cascade do |t|
    t.integer "exercise_collection_id"
    t.integer "exercise_id"
  end

  add_index "exercise_collections_exercises", ["exercise_collection_id"], name: "index_exercise_collections_exercises_on_exercise_collection_id", using: :btree
  add_index "exercise_collections_exercises", ["exercise_id"], name: "index_exercise_collections_exercises_on_exercise_id", using: :btree

  create_table "exercise_tags", force: :cascade do |t|
    t.integer "exercise_id"
    t.integer "tag_id"
    t.integer "factor",      default: 1
  end

  create_table "exercises", force: :cascade do |t|
    t.text     "description"
    t.integer  "execution_environment_id"
    t.string   "title",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.text     "instructions"
    t.boolean  "public"
    t.string   "user_type",                limit: 255
    t.string   "token",                    limit: 255
    t.boolean  "hide_file_tree"
    t.boolean  "allow_file_creation"
    t.boolean  "allow_auto_completion",                default: false
    t.integer  "expected_difficulty",                  default: 1
  end

  create_table "exercises_proxy_exercises", id: false, force: :cascade do |t|
    t.integer  "proxy_exercise_id"
    t.integer  "exercise_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "exercises_proxy_exercises", ["exercise_id"], name: "index_exercises_proxy_exercises_on_exercise_id", using: :btree
  add_index "exercises_proxy_exercises", ["proxy_exercise_id"], name: "index_exercises_proxy_exercises_on_proxy_exercise_id", using: :btree

  create_table "external_users", force: :cascade do |t|
    t.integer  "consumer_id"
    t.string   "email",       limit: 255
    t.string   "external_id", limit: 255
    t.string   "name",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "file_templates", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.text     "content"
    t.integer  "file_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "file_types", force: :cascade do |t|
    t.string   "editor_mode",    limit: 255
    t.string   "file_extension", limit: 255
    t.integer  "indent_size"
    t.string   "name",           limit: 255
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "executable"
    t.boolean  "renderable"
    t.string   "user_type",      limit: 255
    t.boolean  "binary"
  end

  create_table "files", force: :cascade do |t|
    t.text     "content"
    t.integer  "context_id"
    t.string   "context_type",     limit: 255
    t.integer  "file_id"
    t.integer  "file_type_id"
    t.boolean  "hidden"
    t.string   "name",             limit: 255
    t.boolean  "read_only"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "native_file",      limit: 255
    t.string   "role",             limit: 255
    t.string   "hashed_content",   limit: 255
    t.string   "feedback_message", limit: 255
    t.float    "weight"
    t.string   "path",             limit: 255
    t.integer  "file_template_id"
  end

  add_index "files", ["context_id", "context_type"], name: "index_files_on_context_id_and_context_type", using: :btree

  create_table "hints", force: :cascade do |t|
    t.integer  "execution_environment_id"
    t.string   "locale",                   limit: 255
    t.text     "message"
    t.string   "name",                     limit: 255
    t.string   "regular_expression",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "internal_users", force: :cascade do |t|
    t.integer  "consumer_id"
    t.string   "email",                           limit: 255
    t.string   "name",                            limit: 255
    t.string   "role",                            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "crypted_password",                limit: 255
    t.string   "salt",                            limit: 255
    t.integer  "failed_logins_count",                         default: 0
    t.datetime "lock_expires_at"
    t.string   "unlock_token",                    limit: 255
    t.string   "remember_me_token",               limit: 255
    t.datetime "remember_me_token_expires_at"
    t.string   "reset_password_token",            limit: 255
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "activation_state",                limit: 255
    t.string   "activation_token",                limit: 255
    t.datetime "activation_token_expires_at"
  end

  add_index "internal_users", ["activation_token"], name: "index_internal_users_on_activation_token", using: :btree
  add_index "internal_users", ["email"], name: "index_internal_users_on_email", unique: true, using: :btree
  add_index "internal_users", ["remember_me_token"], name: "index_internal_users_on_remember_me_token", using: :btree
  add_index "internal_users", ["reset_password_token"], name: "index_internal_users_on_reset_password_token", using: :btree

  create_table "interventions", force: :cascade do |t|
    t.string   "name"
    t.text     "markup"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lti_parameters", force: :cascade do |t|
    t.integer  "external_users_id"
    t.integer  "consumers_id"
    t.integer  "exercises_id"
    t.jsonb    "lti_parameters",    default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proxy_exercises", force: :cascade do |t|
    t.string   "title"
    t.string   "description"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "remote_evaluation_mappings", force: :cascade do |t|
    t.integer  "user_id",          null: false
    t.integer  "exercise_id",      null: false
    t.string   "validation_token", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "request_for_comments", force: :cascade do |t|
    t.integer  "user_id",                                    null: false
    t.integer  "exercise_id",                                null: false
    t.integer  "file_id",                                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",      limit: 255
    t.text     "question"
    t.boolean  "solved",                     default: false
    t.integer  "submission_id"
    t.text     "thank_you_note"
  end

  create_table "searches", force: :cascade do |t|
    t.integer  "exercise_id", null: false
    t.integer  "user_id",     null: false
    t.string   "user_type",   null: false
    t.string   "search"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "structured_error_attributes", force: :cascade do |t|
    t.integer  "structured_error_id"
    t.integer  "error_template_attribute_id"
    t.string   "value"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "match"
  end

  create_table "structured_errors", force: :cascade do |t|
    t.integer  "error_template_id"
    t.integer  "file_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "exercise_id"
    t.float    "score"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cause",       limit: 255
    t.string   "user_type",   limit: 255
  end

  add_index "submissions", ["exercise_id"], name: "index_submissions_on_exercise_id", using: :btree
  add_index "submissions", ["user_id"], name: "index_submissions_on_user_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "user_type"
    t.integer  "request_for_comment_id"
    t.string   "subscription_type"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.boolean  "deleted"
  end

  create_table "tags", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "testruns", force: :cascade do |t|
    t.boolean  "passed"
    t.text     "output"
    t.integer  "file_id"
    t.integer  "submission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cause"
  end

  create_table "user_exercise_feedbacks", force: :cascade do |t|
    t.integer  "exercise_id",                                             null: false
    t.integer  "user_id",                                                 null: false
    t.string   "user_type",                                               null: false
    t.integer  "difficulty"
    t.integer  "working_time_seconds"
    t.string   "feedback_text"
    t.integer  "user_estimated_worktime"
    t.datetime "created_at",              default: '2017-11-20 18:20:25', null: false
    t.datetime "updated_at",              default: '2017-11-20 18:20:25', null: false
  end

  create_table "user_exercise_interventions", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "user_type"
    t.integer  "exercise_id"
    t.integer  "intervention_id"
    t.integer  "accumulated_worktime_s"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_proxy_exercise_exercises", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "user_type"
    t.integer  "proxy_exercise_id"
    t.integer  "exercise_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reason"
  end

  add_index "user_proxy_exercise_exercises", ["exercise_id"], name: "index_user_proxy_exercise_exercises_on_exercise_id", using: :btree
  add_index "user_proxy_exercise_exercises", ["proxy_exercise_id"], name: "index_user_proxy_exercise_exercises_on_proxy_exercise_id", using: :btree
  add_index "user_proxy_exercise_exercises", ["user_type", "user_id"], name: "index_user_proxy_exercise_exercises_on_user_type_and_user_id", using: :btree

end
