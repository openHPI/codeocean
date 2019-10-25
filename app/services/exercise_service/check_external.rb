# frozen_string_literal: true

module ExerciseService
  class CheckExternal < ServiceBase
    def initialize(uuid:, codeharbor_link:)
      @uuid = uuid
      @codeharbor_link = codeharbor_link
    end

    def execute
      response = connection.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = 'Bearer ' + @codeharbor_link.api_key
        req.body = {uuid: @uuid}.to_json
      end
      response_hash = JSON.parse(response.body, symbolize_names: true)

      {error: false}.merge(response_hash.slice(:message, :exercise_found, :update_right))
    rescue Faraday::Error => e
      {error: true, message: t('exercises.export_exercise.error', message: e.message)}
    end

    private

    def connection
      Faraday.new(url: @codeharbor_link.check_uuid_url) do |faraday|
        faraday.options[:open_timeout] = 5
        faraday.options[:timeout] = 5

        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
