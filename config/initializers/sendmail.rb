if CodeOcean::Application.config.action_mailer.delivery_method == :sendmail
  CodeOcean::Application.config.action_mailer.sendmail_settings = CodeOcean::Config.new(:sendmail).read
end
