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

ActiveRecord::Schema.define(version: 20170202160825) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "code_harbor_links", force: :cascade do |t|
    t.string   "oauth2token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "file_id"
    t.string   "user_type"
    t.integer  "row"
    t.integer  "column"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["file_id"], name: "index_comments_on_file_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "consumers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "oauth_key"
    t.string   "oauth_secret"
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
    t.string   "docker_image"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "run_command"
    t.string   "test_command"
    t.string   "testing_framework"
    t.text     "help"
    t.string   "exposed_ports"
    t.integer  "permitted_execution_time"
    t.integer  "user_id"
    t.string   "user_type"
    t.integer  "pool_size"
    t.integer  "file_type_id"
    t.integer  "memory_limit"
    t.boolean  "network_enabled"
  end

  create_table "exercises", force: :cascade do |t|
    t.text     "description"
    t.integer  "execution_environment_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.text     "instructions"
    t.boolean  "public"
    t.string   "user_type"
    t.string   "token"
    t.boolean  "hide_file_tree"
    t.boolean  "allow_file_creation"
    t.boolean  "allow_auto_completion",    default: false
  end

  create_table "external_users", force: :cascade do |t|
    t.integer  "consumer_id"
    t.string   "email"
    t.string   "external_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "file_templates", force: :cascade do |t|
    t.string   "name"
    t.text     "content"
    t.integer  "file_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "file_types", force: :cascade do |t|
    t.string   "editor_mode"
    t.string   "file_extension"
    t.integer  "indent_size"
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "executable"
    t.boolean  "renderable"
    t.string   "user_type"
    t.boolean  "binary"
  end

  create_table "files", force: :cascade do |t|
    t.text     "content"
    t.integer  "context_id"
    t.string   "context_type"
    t.integer  "file_id"
    t.integer  "file_type_id"
    t.boolean  "hidden"
    t.string   "name"
    t.boolean  "read_only"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "native_file"
    t.string   "role"
    t.string   "hashed_content"
    t.string   "feedback_message"
    t.float    "weight"
    t.string   "path"
    t.integer  "file_template_id"
  end

  add_index "files", ["context_id", "context_type"], name: "index_files_on_context_id_and_context_type", using: :btree

  create_table "hints", force: :cascade do |t|
    t.integer  "execution_environment_id"
    t.string   "locale"
    t.text     "message"
    t.string   "name"
    t.string   "regular_expression"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "internal_users", force: :cascade do |t|
    t.integer  "consumer_id"
    t.string   "email"
    t.string   "name"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "crypted_password"
    t.string   "salt"
    t.integer  "failed_logins_count",             default: 0
    t.datetime "lock_expires_at"
    t.string   "unlock_token"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "activation_state"
    t.string   "activation_token"
    t.datetime "activation_token_expires_at"
  end

  add_index "internal_users", ["activation_token"], name: "index_internal_users_on_activation_token", using: :btree
  add_index "internal_users", ["email"], name: "index_internal_users_on_email", unique: true, using: :btree
  add_index "internal_users", ["remember_me_token"], name: "index_internal_users_on_remember_me_token", using: :btree
  add_index "internal_users", ["reset_password_token"], name: "index_internal_users_on_reset_password_token", using: :btree

  create_table "lti_parameters", force: :cascade do |t|
    t.integer  "external_users_id"
    t.integer  "consumers_id"
    t.integer  "exercises_id"
    t.jsonb    "lti_parameters",    default: {}, null: false
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
    t.integer  "user_id",       null: false
    t.integer  "exercise_id",   null: false
    t.integer  "file_id",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
    t.text     "question"
    t.boolean  "solved"
    t.integer  "submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "exercise_id"
    t.float    "score"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cause"
    t.string   "user_type"
  end

  create_table "testruns", force: :cascade do |t|
    t.boolean  "passed"
    t.text     "output"
    t.integer  "file_id"
    t.integer  "submission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
