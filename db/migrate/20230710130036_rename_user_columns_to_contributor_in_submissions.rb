# frozen_string_literal: true

class RenameUserColumnsToContributorInSubmissions < ActiveRecord::Migration[7.0]
  def change
    change_table :submissions do |t|
      t.rename :user_id, :contributor_id
      t.rename :user_type, :contributor_type
    end
  end
end
