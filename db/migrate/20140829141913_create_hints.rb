class CreateHints < ActiveRecord::Migration
  def change
    create_table :hints do |t|
      t.belongs_to :execution_environment
      t.string :locale
      t.text :message
      t.string :name
      t.string :regular_expression
      t.timestamps
    end
  end
end
