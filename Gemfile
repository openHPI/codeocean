source 'https://rubygems.org'

gem 'bcrypt'
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'concurrent-ruby'
gem 'docker-api', require: 'docker'
gem 'factory_bot_rails'
gem 'forgery'
gem 'highline'
gem 'jbuilder'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'ims-lti', '< 2.0.0'
gem 'kramdown'
gem 'newrelic_rpm'
gem 'pg'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '5.2.1'
gem 'rails-i18n'
gem 'ransack'
gem 'rubytree'
gem 'sass-rails'
gem 'slim-rails'
gem 'bootstrap_pagedown'
gem 'sorcery'
gem 'turbolinks', '< 5.0.0' # newer versions prevent loading ACE if the page containing is not accessed directly / refreshed
gem 'uglifier'
gem 'tubesock', git: 'https://github.com/gosukiwi/tubesock', branch: 'patch-1' # Switch to a fork which is compatible with Rails 5
gem 'faye-websocket'
gem 'nokogiri'
gem 'd3-rails'
gem 'rest-client'
gem 'rubyzip'
gem 'mnemosyne-ruby'
gem 'whenever', require: false

group :development, :staging do
  gem 'bootsnap', require: false
  gem 'listen'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano'
  gem 'capistrano3-puma'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-upload-config'
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-rspec'
  gem 'web-console'
end

group :development, :test, :staging do
  gem 'spring'
end

group :test do
  gem 'rails-controller-testing'
  gem 'autotest-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'codeclimate-test-reporter', require: false
  gem 'database_cleaner'
  gem 'nyan-cat-formatter'
  gem 'rspec-autotest'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end
