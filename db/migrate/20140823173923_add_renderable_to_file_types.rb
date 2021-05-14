# frozen_string_literal: true

class AddRenderableToFileTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :file_types, :renderable, :boolean
  end
end
