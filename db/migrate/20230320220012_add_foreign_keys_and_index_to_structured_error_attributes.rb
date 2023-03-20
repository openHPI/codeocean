# frozen_string_literal: true

class AddForeignKeysAndIndexToStructuredErrorAttributes < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :structured_error_attributes, :structured_errors
    add_foreign_key :structured_error_attributes, :error_template_attributes
    add_index :structured_error_attributes, :structured_error_id
  end
end
