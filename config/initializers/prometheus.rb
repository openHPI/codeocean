# frozen_string_literal: true

require 'code_ocean/config'
require 'prometheus/record'

return unless CodeOcean::Config.new(:code_ocean).read[:prometheus_exporter][:enabled] && !defined?(Rails::Console)
return if %w[db: assets:].any? {|task| Rake.application.top_level_tasks.to_s.include?(task) }

# Add metric callbacks to all models
ActiveSupport.on_load :active_record do
  include Prometheus::Record
end

# Initialization is performed in config/application.rb
