# frozen_string_literal: true

class AddMatchToStructuredErrorAttribute < ActiveRecord::Migration[4.2]
  def change
    add_column :structured_error_attributes, :match, :boolean
  end
end
