class CreateLtiParameters < ActiveRecord::Migration
  def change
    create_table :lti_parameters do |t|
      t.belongs_to :external_users
      t.belongs_to :consumers
      t.belongs_to :exercises
      t.jsonb :lti_parameters, null: false, default: '{}'
      t.timestamps
    end
  end
end