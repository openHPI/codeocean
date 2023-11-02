# frozen_string_literal: true

# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS', max_threads_count)
threads min_threads_count, max_threads_count

# Specifies that the worker count should equal the number of processors in production.
if %w[production staging].include? ENV['RAILS_ENV']
  require 'concurrent-ruby'
  worker_count = Integer(ENV.fetch('WEB_CONCURRENCY') { Concurrent.physical_processor_count })
  workers worker_count if worker_count > 1
end

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

# Specifies the `port` that Puma will listen on to receive requests; default is 7000.
port ENV.fetch('PORT', 7000)

# Specifies the `environment` that Puma will run in.
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

##########################
##### CUSTOM OPTIONS #####
##########################

# Specifies the `state_path` that Pumactl will use.
state_path 'tmp/pids/puma.state'

# Activate control app for Pumactl.
activate_control_app 'unix://tmp/sockets/pumactl.sock'

# Only bind to systemd activated sockets, ignoring other binds.
# If no systemd activated sockets are given, regular binds apply.
bind_to_activated_sockets 'only'

# Refresh Gemfile during phased-restarts.
prune_bundler

# Fork all workers from worker 0 to reduce memory footprint and allow phased restarts.
# For successful phased restarts, we need at least 3 workers (see doc).
# See https://github.com/puma/puma/blob/master/docs/fork_worker.md.
# Passing `0` will disable automatic reforking, which currently breaks with SdNotify.
# See https://github.com/puma/puma/issues/3273.
fork_worker 0

# Disable explicit preloading of our app.
# With `fork_worker`, we will have an implicit preloading.
preload_app! false

# Disable automatic tagging of the service.
tag ''

# Specifies the output redirection that Puma will use.
# Params: stdout, stderr, append?
stdout_redirect 'log/puma_access.log', 'log/puma_error.log', true if %w[production staging].include? ENV['RAILS_ENV']

# Before performing a hot restart (not on phased restarts), send another watchdog message
# TODO: Consider `on_booted` as well, which currently breaks with Pumactl.
on_restart do
  require 'puma/sd_notify'
  Puma::SdNotify.watchdog
end

# Note on Phased Restarts:
# - Phased Restarts are only supported in cluster mode with multiple workers (i.e., not in development).
# - The Puma binary won't be upgraded on phased restarts, but since we have the unattended-upgrades, this is not a major issue.
# - See https://github.com/casperisfine/puma/blob/master/docs/restart.md.
