# frozen_string_literal: true

class RenamePublishedToPublic < ActiveRecord::Migration[4.2]
  def change
    rename_column :exercises, :published, :public
  end
end
