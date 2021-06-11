# frozen_string_literal: true

class RemoveWaitingTimeFromRunners < ActiveRecord::Migration[6.1]
  def change
    remove_column :runners, :waiting_time
  end
end
