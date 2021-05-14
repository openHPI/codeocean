# frozen_string_literal: true

class CreateRequestForComments < ActiveRecord::Migration[4.2]
  def change
    create_table :request_for_comments do |t|
      t.integer :requestorid, null: false
      t.integer :exerciseid, null: false
      t.integer :fileid, null: false
      t.timestamp :requested_at

      t.timestamps
    end
  end
end
