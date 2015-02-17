module CodeOcean
  class Config
    def initialize(filename)
      @filename = filename
    end

    def read(options = {})
      path = Rails.root.join('config', "#{@filename}.yml#{options[:erb] ? '.erb' : ''}")
      if ::File.exist?(path)
        content = options[:erb] ? YAML.load(ERB.new(::File.new(path, 'r').read).result) : YAML.load_file(path)
        content[Rails.env].with_indifferent_access
      else
        fail(Error, "Configuration file not found: #{path}")
      end
    end

    class Error < RuntimeError; end
  end
end
