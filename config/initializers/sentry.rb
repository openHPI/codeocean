# frozen_string_literal: true

Sentry.init do |config|
  # Do not send full list of gems with each event
  config.send_modules = false

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sampler = lambda do |sampling_context|
    # if this is the continuation of a trace, just use that decision (rate controlled by the caller)
    unless sampling_context[:parent_sampled].nil?
      next sampling_context[:parent_sampled]
    end

    # transaction_context is the transaction object in hash form
    # keep in mind that sampling happens right after the transaction is initialized
    # for example, at the beginning of the request
    transaction_context = sampling_context[:transaction_context]

    # transaction_context helps you sample transactions with more sophistication
    # for example, you can provide different sample rates based on the operation or name
    op = transaction_context[:op]
    transaction_name = transaction_context[:name]

    case op
      when /http/
        # for Rails applications, transaction_name would be the request's path (env["PATH_INFO"]) instead of "Controller#action"
        case transaction_name
          when '/', '/ping'
            0.00 # ignore health check
          else
            0.01
        end
      else
        0.0 # ignore all other transactions
    end
  end
end
