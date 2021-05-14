# frozen_string_literal: true

class CreateInternalUsers < ActiveRecord::Migration[4.2]
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
