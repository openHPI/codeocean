# frozen_string_literal: true

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
