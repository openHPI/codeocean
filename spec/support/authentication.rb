# frozen_string_literal: true

module Authentication
  def sign_in(user, password)
    page.driver.post(sessions_url, email: user.email, password:)
  end
end

module RequestLoginHelper
  def login_as(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.include Authentication, type: :system
  config.include RequestLoginHelper, type: :request
end
