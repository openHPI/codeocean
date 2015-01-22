class CreateConsumers < ActiveRecord::Migration
  def change
    create_table :consumers do |t|
      t.string :name
      t.timestamps
    end
  end
end
