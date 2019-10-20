# frozen_string_literal: true

module ExerciseService
  class PushExternal < ServiceBase
    CODEHARBOR_PUSH_LINK = Rails.env.production? ? 'https://codeharbor.openhpi.de/import_exercise' : 'http://localhost:3001/import_exercise'
    def initialize(zip:, codeharbor_link:)
      @zip = zip
      @codeharbor_link = codeharbor_link
    end

    def execute
      body = @zip.string
      begin
        conn = Faraday.new(url: CODEHARBOR_PUSH_LINK) do |faraday|
          faraday.adapter Faraday.default_adapter
        end

        response = conn.post do |request|
          request.headers['Content-Type'] = 'application/zip'
          request.headers['Content-Length'] = body.length.to_s
          request.headers['Authorization'] = 'Bearer ' + @codeharbor_link.api_key
          request.body = body
        end

        return response.success? ? nil : response.body
      rescue StandardError => e
        return e.message
      end
    end
  end
end
