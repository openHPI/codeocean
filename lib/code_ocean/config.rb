module CodeOcean
  class Config
    def initialize(filename)
      @filename = filename
    end

    def read
      path = Rails.root.join('config', "#{@filename}.yml")
      if File.exists?(path)
        YAML.load_file(path)[Rails.env].symbolize_keys
      end
    end
  end
end
