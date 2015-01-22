class CreateFileTypes < ActiveRecord::Migration
  def change
    create_table :file_types do |t|
      t.string :editor_mode
      t.string :file_extension
      t.integer :indent_size
      t.string :name
      t.belongs_to :user
      t.timestamps
    end
  end
end
