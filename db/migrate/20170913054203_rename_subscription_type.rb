# frozen_string_literal: true

class RenameSubscriptionType < ActiveRecord::Migration[4.2]
  def change
    rename_column :subscriptions, :type, :subscription_type
  end
end
