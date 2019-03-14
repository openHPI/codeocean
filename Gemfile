source 'https://rubygems.org'

gem 'bcrypt'
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'concurrent-ruby'
gem 'docker-api', require: 'docker'
gem 'factory_bot_rails', '>= 5.0.1'
gem 'forgery'
gem 'highline'
gem 'jbuilder'
gem 'jquery-rails', '>= 4.3.3'
gem 'ims-lti', '< 2.0.0'
gem 'kramdown'
gem 'newrelic_rpm'
gem 'pg'
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '5.2.2.1'
gem 'rails-i18n', '>= 5.1.3'
gem 'i18n-js'
gem 'ransack', '>= 2.1.1'
gem 'rubytree'
gem 'sass-rails', '>= 5.0.7'
gem 'slim-rails', '>= 3.2.0'
gem 'pagedown-bootstrap-rails', '>= 2.1.4'
gem 'sorcery'
gem 'turbolinks'
gem 'uglifier'
gem 'tubesock', git: 'https://github.com/gosukiwi/tubesock', branch: 'patch-1' # Switch to a fork which is compatible with Rails 5
gem 'faye-websocket'
gem 'eventmachine', '1.0.9.1' # explicitly added, this is used by faye-websocket, newer versions might crash or
gem 'nokogiri'
gem 'webpacker', '>= 4.0.2'
gem 'rest-client'
gem 'rubyzip'
gem 'mnemosyne-ruby'
gem 'whenever', require: false
gem 'rails-timeago', '>= 2.17.1'

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
  gem 'web-console', '>= 3.7.0'
end

group :development, :test, :staging do
  gem 'spring'
end

group :test do
  gem 'rails-controller-testing', '>= 1.0.4'
  gem 'autotest-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'database_cleaner'
  gem 'nyan-cat-formatter'
  gem 'rspec-autotest'
  gem 'rspec-rails', '>= 3.8.2'
  gem 'simplecov', require: false
end
