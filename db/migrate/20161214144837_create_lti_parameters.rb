class CreateLtiParameters < ActiveRecord::Migration
  def change
    create_table :lti_parameters do |t|
      t.string :external_user_id
      t.belongs_to :consumers
      t.belongs_to :exercises
      t.column :lti_parameters, :jsonb

      t.timestamps
    end
  end
end
