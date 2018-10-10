source 'https://rubygems.org'

gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'bcrypt'
gem 'bootstrap-will_paginate'
gem 'carrierwave'
gem 'concurrent-ruby'
gem 'concurrent-ruby-ext', platform: :ruby
gem 'activerecord-deprecated_finders', require: 'active_record/deprecated_finders'
gem 'docker-api', require: 'docker'
gem 'factory_bot_rails', '>= 4.8.2'
gem 'forgery'
gem 'highline'
gem 'jbuilder'
gem 'jquery-rails', '>= 4.3.1'
gem 'jquery-turbolinks', '>= 2.1.0'
gem 'ims-lti', '1.1.10' # version 1.1.13 will crash, because @provider.valid_request?(request) on lti.rb line 89 will return false.
gem 'kramdown'
gem 'newrelic_rpm'
gem 'pg', '< 1.0', platform: :ruby
gem 'pry-byebug'
gem 'puma'
gem 'pundit'
gem 'rails', '4.2.10'
gem 'rails-i18n', '>= 4.0.9'
gem 'ransack', '>= 1.8.7'
gem 'rubytree'
gem 'sass-rails', '>= 5.0.7'
gem 'sdoc', group: :doc
gem 'slim-rails', '>= 3.1.3'
gem 'bootstrap_pagedown', '>= 1.1.0'
gem 'pagedown-rails', '>= 1.1.4'
gem 'sorcery'
gem 'thread_safe'
gem 'turbolinks', '>= 2.5.4', '< 5.0.0' # newer versions prevent loading ACE if the page containing is not accessed directly / refreshed
gem 'uglifier'
gem 'will_paginate'
gem 'tubesock'
gem 'faye-websocket'
gem 'eventmachine', '1.0.9.1' # explicitly added, this is used by faye-websocket, version 1.2.5 still has an error in eventmachine.rb:202: [BUG] Segmentation fault, which is not yet fixed and causes the whole ruby process to crash
gem 'nokogiri', '>= 1.8.5'
gem 'd3-rails', '~> 4.13', '>= 4.13.0'
gem 'rest-client'
gem 'rubyzip'
gem 'mnemosyne-ruby', '~> 1.0'
gem 'whenever', require: false

group :development, :staging do
  gem 'better_errors', platform: :ruby
  gem 'binding_of_caller', platform: :ruby
  gem 'capistrano'
  gem 'capistrano3-puma'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-upload-config'
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-rspec'
  gem 'web-console', '>= 3.3.0', platform: :ruby
end

group :development, :test, :staging do
  gem 'byebug', platform: :ruby
  gem 'spring'
end

group :test do
  gem 'autotest-rails'
  gem 'capybara', '>= 3.3.1'
  gem 'capybara-selenium', '>= 0.0.6'
  gem 'headless'
  gem 'codeclimate-test-reporter', require: false
  gem 'database_cleaner'
  gem 'nyan-cat-formatter'
  gem 'rake'
  gem 'rspec-autotest'
  gem 'rspec-rails', '>= 3.7.2'
  gem 'simplecov', require: false
end
