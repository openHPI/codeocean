require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'

module CodeOcean
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.available_locales = [:de, :en]

    # Add inflection for Zeitwerk
    ActiveSupport::Inflector.inflections(:en) do |inflect|
      inflect.acronym 'IO'
    end

    extra_paths = %W[
      #{config.root}/lib
    ]

    # Add generators, they don't have a module structure that matches their directory structure.
    extra_paths << "#{config.root}/lib/generators"

    config.add_autoload_paths_to_load_path = false
    config.autoload_paths += extra_paths
    config.eager_load_paths += extra_paths

    config.action_cable.mount_path = '/cable'

    config.telegraf.tags = { application: 'codeocean' }

    config.after_initialize do
      # Initialize the counters according to the db
      Prometheus::Controller.initialize_metrics
    end
  end
end
