# frozen_string_literal: true

class AddDescriptionAndHintToErrorTemplate < ActiveRecord::Migration[4.2]
  def change
    add_column :error_templates, :description, :text
    add_column :error_templates, :hint, :text

    add_column :error_template_attributes, :description, :text
    add_column :error_template_attributes, :important, :boolean
  end
end
