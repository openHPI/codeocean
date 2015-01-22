class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.text :code
      t.belongs_to :exercise
      t.float :score
      t.belongs_to :user
      t.timestamps
    end
  end
end
