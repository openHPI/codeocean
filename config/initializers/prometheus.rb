# frozen_string_literal: true

return unless CodeOcean::Config.new(:code_ocean).read[:prometheus_exporter][:enabled]
return if %w[db: assets:].any? { |task| Rake.application.top_level_tasks.to_s.include?(task) }

# Add metric callbacks to all models
ApplicationRecord.include Prometheus::Record

# Initialize the counters according to the db
Prometheus::Controller.initialize_metrics
