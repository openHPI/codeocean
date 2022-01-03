# frozen_string_literal: true

require 'factory_bot'

# Use "old" FactoryBot default to allow auto-creating associations for #build
FactoryBot.use_parent_strategy = false

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
