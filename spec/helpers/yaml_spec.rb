# frozen_string_literal: true

require 'find'
require 'yaml'

describe 'yaml config files' do
  Find.find(__dir__, 'config') do |path|
    next unless /.*.\.yml/.match?(path)

    it "loads #{path} without syntax error" do
      expect { YAML.load_file(path) }.not_to raise_error
    end
  end
end
