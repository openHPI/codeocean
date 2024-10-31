# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bcrypt'
gem 'bootsnap', require: false
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'charlock_holmes', require: 'charlock_holmes/string'
gem 'csv'
gem 'docker-api', require: 'docker'
gem 'eventmachine'
gem 'factory_bot_rails'
gem 'faraday'
gem 'faraday-net_http_persistent'
gem 'faye-websocket'
gem 'forgery'
gem 'highline'
gem 'http_accept_language'
gem 'i18n-js'
gem 'ims-lti', '< 2.0.0' # Version 2 implements LTI 2.0, which is deprecated. Hence, we stay with version 1.
gem 'jbuilder'
gem 'json_schemer'
gem 'js-routes'
gem 'jwt'
gem 'kramdown'
gem 'kramdown-parser-gfm'
gem 'mimemagic'
gem 'net-http-persistent'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'nokogiri'
gem 'pg'
gem 'proformaxml', '~> 1.5.1'
gem 'prometheus_exporter'
gem 'puma'
gem 'pundit'
gem 'rails', '~> 7.2.2'
gem 'rails_admin'
gem 'rails-i18n'
gem 'rails-timeago'
gem 'ransack'
gem 'rubytree'
gem 'rubyzip'
gem 'sassc-rails'
gem 'shakapacker', '8.0.2'
gem 'slim-rails'
gem 'solid_cable'
gem 'solid_queue'
gem 'sorcery'
gem 'sprockets-rails'
gem 'telegraf'
gem 'terser', require: false
gem 'tubesock', github: 'openhpi/tubesock'
gem 'turbolinks'
gem 'whenever', require: false
gem 'zxcvbn-ruby', require: 'zxcvbn'

# Error Tracing
gem 'mnemosyne-ruby'
gem 'stackprof' # Must be loaded before the Sentry SDK.
gem 'sentry-rails' # rubocop:disable Bundler/OrderedGems
gem 'sentry-ruby'

group :development do
  gem 'web-console'
end

group :development, :staging do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman'
  gem 'i18n-tasks'
  gem 'letter_opener'
  gem 'listen'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rack-mini-profiler'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'slim_lint', require: false
end

group :test do
  gem 'capybara'
  gem 'rails-controller-testing'
  gem 'rspec-collection_matchers'
  gem 'rspec-github', require: false
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end
