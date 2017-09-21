class AddDeletedToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :deleted, :boolean
  end
end
