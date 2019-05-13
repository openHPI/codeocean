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
gem 'ims-lti', '< 3.0.0'
gem 'kramdown'
gem 'newrelic_rpm'
gem 'pg'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '5.2.3'
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
gem 'mnemosyne-ruby'
gem 'whenever', require: false
gem 'rails-timeago'

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
  gem 'database_cleaner'
  gem 'nyan-cat-formatter'
  gem 'rspec-autotest'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end
