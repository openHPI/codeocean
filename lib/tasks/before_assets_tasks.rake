# frozen_string_literal: true

task before_assets_precompile: :environment do
  system('bundle exec i18n export')
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance ['before_assets_precompile']

task before_assets_clobber: :environment do
  system('rm -rf ./tmp/locales.json')
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:clobber'].enhance ['before_assets_clobber']
