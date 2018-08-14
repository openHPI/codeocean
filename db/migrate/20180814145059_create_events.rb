class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :type
      t.string :data
      t.belongs_to :user, polymorphic: true, index: true
      t.belongs_to :exercise, index: true
      t.belongs_to :file, index: true
      t.timestamps null: false
    end
  end
end
