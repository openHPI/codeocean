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
gem 'faye-websocket'
gem 'forgery'
gem 'highline'
gem 'i18n-js'
gem 'ims-lti', '< 3.0.0'
gem 'jbuilder'
gem 'js-routes'
gem 'kramdown'
gem 'mimemagic'
gem 'nokogiri'
gem 'pagedown-bootstrap-rails'
gem 'pg'
gem 'proforma', github: 'openHPI/proforma', tag: 'v0.5.1'
gem 'prometheus_exporter'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '~> 6.1.4'
gem 'rails_admin'
gem 'rails-i18n'
gem 'rails-timeago'
gem 'ransack'
gem 'rest-client'
gem 'rubytree', github: 'evolve75/RubyTree'
gem 'rubyzip'
gem 'sass-rails'
gem 'slim-rails'
gem 'sorcery' # Causes a deprecation warning in Rails 6.0+, see: https://github.com/Sorcery/sorcery/pull/255
gem 'telegraf'
gem 'tubesock', github: 'gosukiwi/tubesock', branch: 'patch-1' # Switch to a fork which is compatible with Rails 5
gem 'turbolinks'
gem 'webpacker'
gem 'whenever', require: false

# Error Tracing
gem 'concurrent-ruby'
gem 'mnemosyne-ruby'
gem 'newrelic_rpm'
gem 'sentry-rails'
gem 'sentry-ruby'

group :development, :staging do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bootsnap', require: false
  gem 'listen'
  gem 'pry-rails'
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-performance'
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'
  gem 'web-console'
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
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end
