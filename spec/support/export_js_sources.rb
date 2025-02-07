# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # In local development, we do not want to precompile assets explicitly.
    # Therefore, we might need to export the translations and routes before running the tests.
    next if enabled?('CI')

    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['before_assets_precompile'].invoke
  end

  private

  def enabled?(env_key, default_value = '0')
    %w[0 n no off false f].exclude?(ENV.fetch(env_key, default_value).downcase)
  end
end
