class CreateInternalUsers < ActiveRecord::Migration
  def change
    create_table :internal_users do |t|
      t.belongs_to :consumer
      t.string :email
      t.string :name
      t.string :role
      t.timestamps
    end
  end
end
