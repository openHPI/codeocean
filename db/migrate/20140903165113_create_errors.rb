class CreateErrors < ActiveRecord::Migration
  def change
    create_table :errors do |t|
      t.belongs_to :execution_environment
      t.text :message
      t.timestamps
    end
  end
end
