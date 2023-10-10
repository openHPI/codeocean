# frozen_string_literal: true

require 'find'
require 'active_support'
require 'rails'

RSpec.describe 'yaml config files' do
  Find.find(__dir__, 'config') do |path|
    next unless /.*.\.yml/.match?(path)

    before do
      app = instance_double Rails::Application
      allow(Rails).to receive_messages(root: Pathname.new('/tmp'), application: app)
      allow(app).to receive(:credentials).and_return({})
    end

    it "loads #{path} without syntax error" do
      expect { ActiveSupport::ConfigurationFile.parse(path) }.not_to raise_error
    end
  end
end
