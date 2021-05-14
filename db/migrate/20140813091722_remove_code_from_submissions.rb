# frozen_string_literal: true

class RemoveCodeFromSubmissions < ActiveRecord::Migration[4.2]
  def change
    remove_column :submissions, :code, :text
  end
end
