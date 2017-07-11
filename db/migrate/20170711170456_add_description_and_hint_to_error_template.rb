class AddDescriptionAndHintToErrorTemplate < ActiveRecord::Migration
  def change
    add_column :error_templates, :description, :text
    add_column :error_templates, :hint, :text

    add_column :error_template_attributes, :description, :text
    add_column :error_template_attributes, :important, :boolean
  end
end
