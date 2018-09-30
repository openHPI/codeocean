# Be sure to restart your server when you modify this file.

Rails.application.config.tap do |config|

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # vis.js
  config.assets.precompile += %w( vis.min.js )
  config.assets.precompile += %w( vis.min.css )

  # Highlight.js
  config.assets.precompile += %w( highlight.min.js )
  config.assets.precompile += %w( highlight-default.min.css )

  # d3.tip
  config.assets.precompile += %w( d3-tip.js )

  # Add additional assets to the asset load path.
  # config.assets.paths << Emoji.images_path
  # Add Yarn node_modules folder to the asset load path.
  # config.assets.paths << Rails.root.join('node_modules')

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in the app/assets
  # folder are already added.
  # config.assets.precompile += %w( admin.js admin.css )
end
