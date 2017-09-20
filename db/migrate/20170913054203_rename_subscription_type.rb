class RenameSubscriptionType < ActiveRecord::Migration
  def change
    rename_column :subscriptions, :type, :subscription_type
  end
end
