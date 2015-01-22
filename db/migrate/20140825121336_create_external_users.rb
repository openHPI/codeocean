class CreateExternalUsers < ActiveRecord::Migration
  def change
    create_table :external_users do |t|
      t.belongs_to :consumer
      t.string :email
      t.string :external_id
      t.string :name
      t.timestamps
    end
  end
end
