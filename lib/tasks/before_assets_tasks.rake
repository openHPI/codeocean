# frozen_string_literal: true

task before_assets_precompile: :environment do
  I18nJS.call(config_file: './config/i18n.yml')
  JsRoutes.generate!(typed: true)
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:precompile'].enhance ['before_assets_precompile']

task before_assets_clobber: :environment do
  FileUtils.rm_rf('./app/javascript/generated/.', secure: true)
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task['assets:clobber'].enhance ['before_assets_clobber']
