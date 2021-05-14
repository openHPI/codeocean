# frozen_string_literal: true

require 'rails/generators'
require 'generators/testing_framework_adapter_generator'
require 'rails_helper'

describe TestingFrameworkAdapterGenerator do
  include Silencer

  describe '#create_testing_framework_adapter' do
    let(:name) { 'TestUnit' }
    let(:path) { Rails.root.join('lib', "#{name.underscore}_adapter.rb") }
    let(:spec_path) { Rails.root.join('spec', 'lib', "#{name.underscore}_adapter_spec.rb") }

    before do
      silenced { Rails::Generators.invoke('testing_framework_adapter', [name]) }
    end

    after do
      File.delete(path)
      File.delete(spec_path)
    end

    it 'generates a correctly named file' do
      expect(File.exist?(path)).to be true
    end

    it 'builds a correct class skeleton' do
      file_content = File.new(path, 'r').read
      expect(file_content&.strip).to start_with("class #{name}Adapter < TestingFrameworkAdapter")
    end

    it 'generates a corresponding test' do
      expect(File.exist?(spec_path)).to be true
    end

    it 'builds a correct test skeleton' do
      file_content = File.new(spec_path, 'r').read
      expect(file_content).to include("describe #{name}Adapter")
      expect(file_content).to include("describe '#parse_output'")
    end
  end
end
