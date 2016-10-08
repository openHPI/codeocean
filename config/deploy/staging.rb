server '10.210.0.50', roles: [:app, :db, :puma_nginx, :web], user: 'debian'
set :rails_env, "staging"
set :branch, ENV['BRANCH'] if ENV['BRANCH']
