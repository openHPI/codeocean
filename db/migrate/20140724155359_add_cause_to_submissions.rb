# frozen_string_literal: true

class AddCauseToSubmissions < ActiveRecord::Migration[4.2]
  def change
    add_column :submissions, :cause, :string
  end
end
