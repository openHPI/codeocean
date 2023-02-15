# frozen_string_literal: true

Sentry.init do |config|
  config.send_modules = true
  config.include_local_variables = true
  config.breadcrumbs_logger = %i[sentry_logger monotonic_active_support_logger http_logger]

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
            ENV.fetch('SENTRY_TRACE_SAMPLE_RATE', 1.0).to_f
        end
      else
        ENV.fetch('SENTRY_TRACE_SAMPLE_RATE', 1.0).to_f # sample all other transactions
    end
  end

  config.before_send_transaction = lambda do |event, _hint|
    url_spans = %w[http.client websocket.client]

    event.spans.each do |span|
      next unless url_spans.include?(span[:op])

      # Replace UUIDs in URLs with asterisks to allow better grouping of similar requests
      span[:description].gsub!(/[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}/i, '*')
    end

    event
  end
end
