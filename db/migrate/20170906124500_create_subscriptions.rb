# frozen_string_literal: true

class CreateSubscriptions < ActiveRecord::Migration[4.2]
  def change
    create_table :subscriptions do |t|
      t.belongs_to :user, polymorphic: true
      t.references :request_for_comment
      t.string :type

      t.timestamps null: false
    end
  end
end
