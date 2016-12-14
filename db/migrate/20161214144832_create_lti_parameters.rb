class CreateLtiParameters < ActiveRecord::Migration
  def change
    create_table :lti_parameters do |t|
      t.string :external_user_id
      t.string :consumer_id
      t.string :exercise_id
      t.text :lti_return_url

      t.timestamps
    end
  end
end
