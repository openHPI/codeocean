# frozen_string_literal: true

module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until ajax_requests_finished?
    end
  end

  def ajax_requests_finished?
    page.evaluate_script('jQuery.active').zero?
  end
end
