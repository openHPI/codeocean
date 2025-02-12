# frozen_string_literal: true

class ExerciseService
  class PushExternal < ExerciseService
    def initialize(zip:, codeharbor_link:)
      super()
      @zip = zip
      @codeharbor_link = codeharbor_link
    end

    def execute
      body = @zip.string
      begin
        response = self.class.connection.post @codeharbor_link.push_url do |request|
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
  end
end
