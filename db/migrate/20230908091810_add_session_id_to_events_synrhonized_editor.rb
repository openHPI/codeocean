# frozen_string_literal: true

class AddSessionIdToEventsSynrhonizedEditor < ActiveRecord::Migration[7.0]
  def change
    add_column :events_synchronized_editor, :session_id, :uuid, null: true
  end
end
