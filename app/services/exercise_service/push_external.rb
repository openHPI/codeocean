# frozen_string_literal: true

module ExerciseService
  class PushExternal < ServiceBase
    def initialize(zip:, codeharbor_link:)
      super()
      @zip = zip
      @codeharbor_link = codeharbor_link
    end

    def execute
      body = @zip.string
      begin
        response = connection.post do |request|
          request.headers['Content-Type'] = 'application/zip'
          request.headers['Content-Length'] = body.length.to_s
          request.headers['Authorization'] = "Bearer #{@codeharbor_link.api_key}"
          request.body = body
        end

        response.success? ? nil : response.body
      rescue StandardError => e
        e.message
      end
    end

    private

    def connection
      Faraday.new(url: @codeharbor_link.push_url) do |faraday|
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
