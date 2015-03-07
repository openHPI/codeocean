set :application, 'code_ocean'
set :config_example_suffix, '.example'
set :deploy_to, '/var/www/app'
set :keep_releases, 3
set :linked_dirs, %w(bin log public/uploads tmp/cache tmp/files tmp/pids tmp/sockets)
set :linked_files, %w(config/action_mailer.yml config/code_ocean.yml config/database.yml config/secrets.yml config/sendmail.yml config/smtp.yml)
set :log_level, :info
set :puma_threads, [0, 16]
set :repo_url, 'git@github.com:openHPI/codeocean.git'

namespace :deploy do
  before 'check:linked_files', 'config:push'

  after :compile_assets, :copy_vendor_assets do
    on roles(fetch(:assets_roles)) do
      within release_path do
        execute :cp, 'vendor/assets/images/*', 'public/assets/'
        execute :cp, '-r', 'vendor/assets/javascripts/ace', 'public/assets/'
      end
    end
  end
end
