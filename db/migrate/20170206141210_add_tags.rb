class AddTags < ActiveRecord::Migration

  def change
    add_column :exercises, :expected_worktime_seconds, :integer, default: 60
    add_column :exercises, :expected_difficulty, :integer, default: 1

    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :exercise_tags do |t|
      t.belongs_to :exercise
      t.belongs_to :tag
      t.integer :factor, default: 1
    end
  end

end
