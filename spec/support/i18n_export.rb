# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # In local development, we do not want to precompile assets explicitly.
    # Therefore, we might need to export the translations before running the tests.
    system('bundle exec i18n export') if ENV['CI'].blank?
  end
end
