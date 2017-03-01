class AddSearch < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.belongs_to :exercise, null: false
      t.belongs_to :user, polymorphic: true, null: false
      t.string :search
      t.timestamps
    end
  end
end
