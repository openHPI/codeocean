# frozen_string_literal: true

class DropActionCableLargePayloads < ActiveRecord::Migration[7.2]
  def change
    # Drop the previously-used table for large payloads in ActionCable.
    # This table was implicitly created by the EnhancedPostgresql adapter.
    # Solid Cable used from now on manages the required schema separately.
    drop_table :action_cable_large_payloads, if_exists: true
  end
end
