# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'
require_relative '../lib/middleware/web_socket_sentry_headers'

module CodeOcean
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks templates generators middleware i18n_tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = ENV.fetch('RAILS_TIME_ZONE', 'UTC')
    # config.eager_load_paths << Rails.root.join("extras")

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.available_locales = %i[de en]

    config.relative_url_root = ENV.fetch('RAILS_RELATIVE_URL_ROOT', '/').to_s

    config.action_cable.mount_path = "#{ENV.fetch('RAILS_RELATIVE_URL_ROOT', '')}/cable"

    # Disable concurrent ActionCable workers to ensure ACE change events keep their order
    config.action_cable.worker_pool_size = 1

    config.telegraf.tags = {application: 'codeocean'}

    config.after_initialize do
      # Initialize the counters according to the db
      Prometheus::Controller.initialize_metrics

      # Initialize the runner environment
      Runner.strategy_class.initialize_environment
    end

    config.action_mailer.preview_paths << Rails.root.join('spec/mailers/previews')

    # Specify default options for Rails generators
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Allow tables in addition to existing default tags
    config.action_view.sanitized_allowed_tags = ActionView::Base.sanitized_allowed_tags + %w[table thead tbody tfoot td tr details summary]

    # Extract Sentry-related parameters from WebSocket connection
    config.middleware.insert_before 0, Middleware::WebSocketSentryHeaders

    # Configure some defaults for the Solid Queue Supervisor
    require_relative 'solid_queue_defaults'
  end
end
