class CreateErrorTemplateAttributes < ActiveRecord::Migration
  def change
    create_table :error_template_attributes do |t|
      t.belongs_to :error_template
      t.string :key
      t.string :regex

      t.timestamps null: false
    end
  end
end
