# frozen_string_literal: true

module CodeOcean
  class Config
    attr_reader :path, :read

    def initialize(filename, options = {})
      @path = Rails.root.join('config', "#{filename}.yml#{options[:erb] ? '.erb' : ''}")
      @read = parse(options)
    end

    private

    def parse(options)
      if ::File.exist?(path)
        yaml_content = ::File.new(path, 'r').read || ''
        yaml_content = ERB.new(yaml_content).result if options[:erb]
        content = YAML.safe_load(yaml_content, aliases: true, permitted_classes: [Range, Symbol])
        content[Rails.env].with_indifferent_access
      else
        raise Error.new("Configuration file not found: #{path}")
      end
    end

    class Error < RuntimeError; end
  end
end
