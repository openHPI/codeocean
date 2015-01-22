class AddRenderableToFileTypes < ActiveRecord::Migration
  def change
    add_column :file_types, :renderable, :boolean
  end
end
