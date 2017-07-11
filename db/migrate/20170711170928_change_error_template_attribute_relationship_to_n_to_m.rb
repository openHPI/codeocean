class ChangeErrorTemplateAttributeRelationshipToNToM < ActiveRecord::Migration
  def change
    remove_belongs_to :error_template_attributes, :error_template
    create_join_table :error_templates, :error_template_attributes
  end
end
