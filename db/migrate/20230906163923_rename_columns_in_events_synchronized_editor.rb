# frozen_string_literal: true

class RenameColumnsInEventsSynchronizedEditor < ActiveRecord::Migration[7.0]
  def change
    change_table :events_synchronized_editor do |t|
      t.rename :action, :editor_action
      t.rename :command, :action
    end
  end
end
