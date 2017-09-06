class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.belongs_to :user, polymorphic: true
      t.references :request_for_comment
      t.string :type

      t.timestamps null: false
    end
  end
end
