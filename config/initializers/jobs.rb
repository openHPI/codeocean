# frozen_string_literal: true

RunnerCleanupJob.perform_now unless Rake.application.top_level_tasks.to_s.match?(/db:|assets:/)
