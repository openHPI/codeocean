# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :avoid_change, :change
RSpec::Matchers.define_negated_matcher :not_include, :include
RSpec::Matchers.define_negated_matcher :not_have_attributes, :have_attributes
RSpec::Matchers.define_negated_matcher :not_eql, :eql

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
