# frozen_string_literal: true

class ExerciseService < ServiceBase
  def self.connection
    @connection ||= Faraday.new do |faraday|
      faraday.options[:open_timeout] = 5
      faraday.options[:timeout] = 5

      faraday.adapter :net_http_persistent
    end
  end
end
