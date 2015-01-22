YAML.load_file(Rails.root.join('config', 'action_mailer.yml'))[Rails.env].each do |key, value|
  CodeOcean::Application.config.action_mailer.send(:"#{key}=", value.respond_to?(:symbolize_keys) ? value.symbolize_keys : value)
end
