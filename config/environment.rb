# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# LTI 1.x uses OAuth 1.0
OAUTH_10_SUPPORT = true

# Initialize the Rails application.
Rails.application.initialize!
