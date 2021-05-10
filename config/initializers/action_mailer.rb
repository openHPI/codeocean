# frozen_string_literal: true

require 'code_ocean/config'

CodeOcean::Config.new(:action_mailer).read.each do |key, value|
  CodeOcean::Application.config.action_mailer.send(:"#{key}=", value.respond_to?(:symbolize_keys) ? value.symbolize_keys : value)
end
