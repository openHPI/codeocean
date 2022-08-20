# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# https://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: https://github.com/javan/whenever

set :output, "#{Whenever.path}/log/whenever/whenever_$(date +%Y%m%d%H%M%S).log"
set :environment, ENV.fetch('RAILS_ENV', nil) if ENV['RAILS_ENV']

every 1.day, at: '3:00 am' do
  rake 'detect_exercise_anomalies:with_at_least[10,50]'
end
