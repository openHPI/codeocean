if CodeOcean::Application.config.action_mailer.delivery_method == :smtp
  CodeOcean::Application.config.action_mailer.sendmail_settings = CodeOcean::Config.new(:smtp).read
end
