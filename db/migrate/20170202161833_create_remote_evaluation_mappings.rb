class CreateRemoteEvaluationMappings < ActiveRecord::Migration
  def change
    create_table :remote_evaluation_mappings do |t|
      t.integer   "user_id",          null: false
      t.integer   "exercise_id",      null: false
      t.string    "validation_token",  null: false
      t.datetime  "created_at"
      t.datetime  "updated_at"
    end
  end
end