# frozen_string_literal: true

require 'rails/generators'

class TestingFrameworkAdapterGenerator < Rails::Generators::NamedBase
  ADAPTER_PATH = ->(name) { Rails.root.join('lib', "#{name.underscore}_adapter.rb") }
  SPEC_PATH = ->(name) { Rails.root.join('spec', 'lib', "#{name.underscore}_adapter_spec.rb") }

  def create_testing_framework_adapter
    create_file ADAPTER_PATH.call(file_name), <<~CODE
            class #{file_name.camelize}Adapter < TestingFrameworkAdapter
              def self.framework_name
                '#{file_name.camelize}'
              end
      #{'      '}
              def parse_output(output)
              end
            end
    CODE
  end

  def create_spec
    create_file SPEC_PATH.call(file_name), <<~CODE
            require 'rails_helper'
      #{'      '}
            describe #{file_name.camelize}Adapter do
              describe '#parse_output' do
              end
            end
    CODE
  end
end
