# frozen_string_literal: true

class RenameUserToContributorInAnomalyNotifications < ActiveRecord::Migration[7.0]
  def change
    # We need to drop and recreate the index because the name would be too long otherwise.
    # Renaming is not possible because the index can have two different names.

    change_table :anomaly_notifications do |t|
      t.remove_index %i[user_type user_id]
      t.rename :user_id, :contributor_id
      t.rename :user_type, :contributor_type
    end

    add_index :anomaly_notifications, %i[contributor_type contributor_id], name: 'index_anomaly_notifications_on_contributor'
  end
end
