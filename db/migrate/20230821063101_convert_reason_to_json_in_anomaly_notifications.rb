# frozen_string_literal: true

class ConvertReasonToJsonInAnomalyNotifications < ActiveRecord::Migration[7.0]
  def up
    AnomalyNotification.where("reason LIKE '%value:%'").find_each do |anomaly_notification|
      reason = anomaly_notification.reason
      reason = reason.gsub('value:', '"value":')
      reason = reason.gsub(/"(\d+\.\d+)"/) {|_| Regexp.last_match(1) }
      anomaly_notification.update!(reason:)
    end
    change_column :anomaly_notifications, :reason, :jsonb, using: 'reason::jsonb'
  end

  def down
    change_column :anomaly_notifications, :reason, :string
  end

  class AnomalyNotification < ActiveRecord::Base; end
end
