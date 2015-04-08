class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.references :user, index: true
      t.references :file, index: true
      t.string :user_type
      t.integer :row
      t.integer :column
      t.string :text

      t.timestamps
    end
  end
end
