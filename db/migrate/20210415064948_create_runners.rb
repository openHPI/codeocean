class CreateRunners < ActiveRecord::Migration[5.2]
  def change
    create_table :runners do |t|
      t.string :runner_id
      t.references :execution_environment
      t.references :user, polymorphic: true
      t.integer :time_limit
      t.float :waiting_time
      t.datetime :last_used

      t.timestamps
    end
  end
end
