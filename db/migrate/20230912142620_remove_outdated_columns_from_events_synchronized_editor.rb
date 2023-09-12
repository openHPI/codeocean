# frozen_string_literal: true

class RemoveOutdatedColumnsFromEventsSynchronizedEditor < ActiveRecord::Migration[7.0]
  def change
    change_table :events_synchronized_editor do |t|
      t.remove :nl
      t.remove :text
    end
  end
end
