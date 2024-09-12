# frozen_string_literal: true

# This module is used to log ActiveRecord queries performed in jobs.
module ActiveRecordLogging
  extend ActiveSupport::Concern

  included do
    around_perform do |_job, block|
      # With our current Solid Queue setup, there is a difference between both logger:
      # - *ActiveRecord::Base.logger*: This logger is used for SQL queries and, normally, writes to the log file only.
      # - *Rails.logger*: The regular logger, which writes to the log file and the console.
      # For the duration of the job, we want to write the SQL queries to the Rails logger, so they show up in the console.
      # See config/solid_queue_logging.rb for more information.
      previous_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Rails.logger
      block.call
      ActiveRecord::Base.logger = previous_logger
    end
  end
end
