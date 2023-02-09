# Environment Variables

The following environment variables are specifically support in CodeOcean and are used to configure the application in addition to the setting files under `config/`.

| Environment Variable | Default | Description |  
|- |- |- |
| `RAILS_ENV` | `development` | Specifies the Rails environment which can be configured using the files in `config/environments` |  
| `RAILS_RELATIVE_URL_ROOT` | `/` | Specifies the subpath of the application, used for links and assets |  
| `SENTRY_DSN` | ` ` | Specifies the [Sentry error reporting](https://sentry.io) endpoint for the Rails server |  
| `SENTRY_JAVASCRIPT_DSN` | ` `    | Specifies the [Sentry error reporting](https://sentry.io) endpoint for the frontend used by browsers |  
| `SENTRY_CURRENT_ENV` | ` ` | Specifies the [Sentry](https://sentry.io) environment used for error reporting |  
| `SENTRY_TRACE_SAMPLE_RATE` | `1.0` | Specifies the sampling rate for traces in [Sentry](https://sentry.io) |  
| `RAILS_LOG_LEVEL` | `info` in production<br>`debug` in development | Specifies how many log messages to print. The available log levels are: `debug`, `info`, `warn`, `error`, `fatal`, and `unknown`. |
| `RAILS_LOG_TO_STDOUT` | `false` in `production` | Enables the server to print log output to the command line |  
| `RAILS_SERVE_STATIC_FILES` | `true` in `development` and `test`<br>`false` in `production` and `staging` | Specifies whether the Rails server should be able to handle requests for non-dynamic resources (e.g., assets) |  
| `RAILS_TIME_ZONE` | `UTC` | Set the time zone and make Active Record auto-convert to this zone for renderings. Run `rake -D time` for a list of tasks for finding time zone names. |
| `BACKTRACE` | `false` | Enables more verbose log output from framework code during debugging |  
| `TRUSTED_IP` | ` ` in `development`    | Enables `BetterErrors` for the given IP addresses during development |  
| `LISTEN_ADDRESS` | `127.0.0.1` in `development` | Specifies the IP address the Vagrant VM server should attach to during development |  
| `HEADLESS_TEST` | `false` | Enables the test environment to work without a window manager for feature tests (e.g., using Vagrant) |  
