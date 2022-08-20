# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[markdown-buttons.png]

# Disable concurrent asset compilation to prevent segfault # https://github.com/sass/sassc-ruby/issues/197
# Reproduce: `rake assets:clobber`, `rake assets:precompile`. If the command succeeds, it worked
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end

# Add node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
