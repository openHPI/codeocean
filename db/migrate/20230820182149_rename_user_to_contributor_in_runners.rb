# frozen_string_literal: true

class RenameUserToContributorInRunners < ActiveRecord::Migration[7.0]
  def change
    change_table :runners do |t|
      t.rename :user_id, :contributor_id
      t.rename :user_type, :contributor_type
    end
  end
end
