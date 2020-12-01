# Be sure to restart your server when you modify this file.

Rails.application.config.tap do |config|

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Add additional assets to the asset load path.
  # config.assets.paths << Emoji.images_path
  # Add Yarn node_modules folder to the asset load path.
  config.assets.paths << Rails.root.join('node_modules')

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in the app/assets
  # folder are already added.
  # config.assets.precompile += %w( admin.js admin.css )
end

# Disable concurrent asset compilation to prevent segfault # https://github.com/sass/sassc-ruby/issues/197
# Reproduce: `rake assets:clobber`, `rake assets:precompile`. If the command succeeds, it worked
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end
