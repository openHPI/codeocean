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
      message = if response_hash[:exercise_found]
                  response_hash[:update_right] ? I18n.t('exercises.export_codeharbor.check.exercise_found') : I18n.t('exercises.export_codeharbor.check.exercise_found_no_right')
                else
                  I18n.t('exercises.export_codeharbor.check.no_exercise')
                end

      {error: false, message: message}.merge(response_hash.slice(:exercise_found, :update_right))
    rescue Faraday::Error, JSON::ParserError
      {error: true, message: I18n.t('exercises.export_codeharbor.error')}
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
