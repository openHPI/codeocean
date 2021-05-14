# frozen_string_literal: true

class AddDeletedToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :deleted, :boolean
  end
end
