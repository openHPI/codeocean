# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bcrypt'
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'charlock_holmes', require: 'charlock_holmes/string'
gem 'docker-api', require: 'docker'
gem 'eventmachine'
gem 'factory_bot_rails'
gem 'faraday'
gem 'faraday-net_http_persistent'
gem 'faye-websocket'
gem 'forgery'
gem 'highline'
gem 'i18n-js'
gem 'ims-lti', '< 2.0.0'
gem 'jbuilder'
gem 'json_schemer'
gem 'js-routes'
gem 'jwt'
gem 'kramdown'
gem 'mimemagic'
gem 'net-http-persistent'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'nokogiri'
gem 'pagedown-bootstrap-rails'
gem 'pg'
gem 'proforma', github: 'openHPI/proforma', tag: 'v0.7.1'
gem 'prometheus_exporter'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '~> 6.1.7'
gem 'rails_admin', '< 3.0.0' # Blocked by https://github.com/railsadminteam/rails_admin/issues/3490
gem 'rails-i18n'
gem 'rails-timeago'
gem 'ransack'
gem 'rest-client'
gem 'rubytree'
gem 'rubyzip'
gem 'sass-rails'
gem 'shakapacker', '6.5.4'
gem 'slim-rails'
gem 'sorcery' # Causes a deprecation warning in Rails 6.0+, see: https://github.com/Sorcery/sorcery/pull/255
gem 'telegraf'
gem 'tubesock'
gem 'turbolinks'
gem 'whenever', require: false
gem 'zxcvbn-ruby', require: 'zxcvbn'

# Error Tracing
gem 'mnemosyne-ruby'
gem 'sentry-rails'
gem 'sentry-ruby'

group :development do
  gem 'web-console'
end

group :development, :staging do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bootsnap', require: false
  gem 'letter_opener'
  gem 'listen'
  gem 'pry-rails'
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'
end

group :development, :test, :staging do
  gem 'spring'
end

group :test do
  gem 'autotest' # required by autotest-rails
  gem 'autotest-rails'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'headless'
  gem 'nyan-cat-formatter'
  gem 'rails-controller-testing'
  gem 'rspec-autotest'
  gem 'rspec-collection_matchers'
  gem 'rspec-github', require: false
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end
