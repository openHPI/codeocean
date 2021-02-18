# frozen_string_literal: true

require 'prometheus_exporter/client'
require 'rails_helper'

module Prometheus
  # A stub to disable server functionality in the specs and stub all registered metrics
  module StubClient
    def send(str)
      # Do nothing
    end
  end

  PrometheusExporter::Client.prepend StubClient
end
