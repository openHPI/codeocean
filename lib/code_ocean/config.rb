# frozen_string_literal: true

module CodeOcean
  class Config
    def initialize(filename)
      @filename = filename
    end

    def read(options = {})
      path = Rails.root.join('config', "#{@filename}.yml#{options[:erb] ? '.erb' : ''}")
      if ::File.exist?(path)
        content = options[:erb] ? YAML.safe_load(ERB.new(::File.new(path, 'r').read).result, aliases: true, permitted_classes: [Range]) : YAML.load_file(path)
        content[Rails.env].with_indifferent_access
      else
        raise Error.new("Configuration file not found: #{path}")
      end
    end

    class Error < RuntimeError; end
  end
end
