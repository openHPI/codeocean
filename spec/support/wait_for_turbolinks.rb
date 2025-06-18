# frozen_string_literal: true

module WaitForTurbolinks
  # Capybara waits ordinary page navigation. With Turbolinks
  # the page is checked immediate. This might be before the
  # Turbolinks navigation finished. This makes system tests brittle.
  # By checking the Turbolinks progress bar we can wait for the
  # Turbolinks request to finish.
  def wait_for_turbolinks
    has_css?('.turbolinks-progress-bar', visible: true)
    has_no_css?('.turbolinks-progress-bar')
  end
end

RSpec.configure do |config|
  config.include WaitForTurbolinks, type: :system
end
