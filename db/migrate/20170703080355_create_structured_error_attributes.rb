class CreateStructuredErrorAttributes < ActiveRecord::Migration
  def change
    create_table :structured_error_attributes do |t|
      t.belongs_to :structured_error
      t.references :error_template_attribute
      t.string :value

      t.timestamps null: false
    end
  end
end
