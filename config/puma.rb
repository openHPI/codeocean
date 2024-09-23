# frozen_string_literal: true

# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# to prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch('RAILS_MAX_THREADS', 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 7000.
port ENV.fetch('PORT', 7000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Specify the PID file. Defaults to tmp/pids/server.pid.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

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
