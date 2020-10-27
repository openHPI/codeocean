source 'https://rubygems.org'

gem 'bcrypt'
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'docker-api', require: 'docker'
gem 'factory_bot_rails'
gem 'forgery'
gem 'highline'
gem 'jbuilder'
gem 'ims-lti', '< 2.0.0'
gem 'kramdown'
gem 'pg'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '6.0.3.4'
gem 'rails-i18n'
gem 'i18n-js'
gem 'ransack'
gem 'rubytree'
gem 'sass-rails'
gem 'slim-rails'
gem 'pagedown-bootstrap-rails'
gem 'sorcery'
gem 'turbolinks'
gem 'uglifier'
gem 'tubesock', git: 'https://github.com/gosukiwi/tubesock', branch: 'patch-1' # Switch to a fork which is compatible with Rails 5
gem 'faye-websocket'
gem 'eventmachine', '1.0.9.1' # explicitly added, this is used by faye-websocket, newer versions might crash or
gem 'nokogiri'
gem 'webpacker'
gem 'rest-client'
gem 'rubyzip'
gem 'faraday'
gem 'proforma', git: 'https://github.com/openHPI/proforma.git', tag: 'v0.5'
gem 'whenever', require: false
gem 'rails-timeago'

# Error Tracing
gem 'concurrent-ruby'
gem 'mnemosyne-ruby'
gem 'newrelic_rpm'
gem 'sentry-raven'

group :development, :staging do
  gem 'bootsnap', require: false
  gem 'listen'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-rspec'
  gem 'web-console'
  gem 'ed25519', require: false # For SSH deployment with ED25519 key
  gem 'bcrypt_pbkdf', require: false # For SSH deployment with ED25519 key
end

group :development, :test, :staging do
  gem 'spring'
end

group :test do
  gem 'rails-controller-testing'
  gem 'autotest' # required by autotest-rails
  gem 'autotest-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'database_cleaner'
  gem 'nyan-cat-formatter'
  gem 'rspec-autotest'
  gem 'rspec-collection_matchers'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end
