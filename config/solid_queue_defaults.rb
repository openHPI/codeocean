# frozen_string_literal: true

# This file must be loaded before other initializers due to the logging configuration.
Rails.application.configure do
  # On shutdown, jobs Solid Queue will wait the specified timeout before forcefully shutting down.
  # Any job not finished by then will be picked up again after a restart.
  config.solid_queue.shutdown_timeout = 10.seconds
  # Remove *successful* jobs from the database after 30 days
  config.solid_queue.clear_finished_jobs_after = 30.days
  config.solid_queue.supervisor_pidfile = Rails.root.join('tmp/pids/solid_queue_supervisor.pid')

  # For Solid Queue, we want to hide regular SQL queries from the console, but still log them to a separate file.
  # For the normal webserver, this dedicated setup is neither needed nor desired.
  next unless Rake.application.top_level_tasks.to_s.include?('solid_queue:')

  # Specify that all logs should be written to the specified log file
  file_name = "#{Rails.env}.solid_queue.log"
  config.paths.add 'log', with: "log/#{file_name}"

  # Send all logs regarding SQL queries to the log file.
  # This will include all queries performed by Solid Queue including periodic job checks.
  log_file = ActiveSupport::Logger.new(Rails.root.join('log', file_name))
  config.active_record.logger = ActiveSupport::BroadcastLogger.new(log_file)

  config.after_initialize do
    # Create a new logger that will write to the console
    console = ActiveSupport::Logger.new($stdout)
    console.level = Rails.logger.level
    # Enable this line to have the same log format as Rails.logger
    # It will include the job name, the job ID for each line
    # console.formatter = Rails.logger.formatter

    ActiveSupport.on_load :solid_queue_record do
      # Once SolidQueue is loaded, we can broadcast its logs to the console, too.
      # Due to the initialization order, this will effectively start logging once SolidQueue is about to start.
      Rails.logger.broadcast_to console
    end
  end
end
