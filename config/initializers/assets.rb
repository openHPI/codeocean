# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Add additional assets to the asset load path.
# We require the config directory to enable asset dependencies on CodeOcean::Config values (stored as YML files in `config`).
Rails.application.config.assets.paths << Rails.root.join('config')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[markdown-buttons.png]
