# frozen_string_literal: true

class RunnerCleanupJob < ApplicationJob
  CLEANUP_INTERVAL = CodeOcean::Config.new(:code_ocean).read[:runner_management][:cleanup_interval].seconds

  after_perform do |_job|
    # re-schedule job
    self.class.set(wait: CLEANUP_INTERVAL).perform_later
  end

  def perform
    Rails.logger.debug(Time.zone.now)
    Runner.inactive_runners.each do |runner|
      Rails.logger.debug("Destroying runner #{runner.runner_id}, unused since #{runner.last_used}")
      runner.destroy
    end
  end
end
