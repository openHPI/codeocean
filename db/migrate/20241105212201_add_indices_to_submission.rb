# frozen_string_literal: true

class AddIndicesToSubmission < ActiveRecord::Migration[7.2]
  def change
    add_index :submissions, :updated_at, order: {updated_at: :desc}
    add_index :submissions, :cause, using: :gin, opclass: :gin_trgm_ops
  end
end
