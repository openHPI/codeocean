# frozen_string_literal: true

class RequireSessionIdForEventSynchronizedEditor < ActiveRecord::Migration[7.0]
  def change
    change_column_null :events_synchronized_editor, :session_id, false
  end
end
