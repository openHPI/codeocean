# frozen_string_literal: true

module Authentication
  def sign_in(user, password)
    page.driver.post(sessions_url, email: user.email, password:)
  end
end

RSpec.configure do |config|
  config.include Authentication, type: :system
end
