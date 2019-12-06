# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :has_content do |actual_content|
  match do |file|
    file.read == actual_content
  end
end
