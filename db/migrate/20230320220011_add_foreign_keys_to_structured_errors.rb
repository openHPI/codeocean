# frozen_string_literal: true

class AddForeignKeysToStructuredErrors < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :structured_errors, :submissions
    add_foreign_key :structured_errors, :error_templates
  end
end
