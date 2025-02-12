# frozen_string_literal: true

class ExerciseService
  class CheckExternal < ExerciseService
    def initialize(uuid:, codeharbor_link:)
      super()
      @uuid = uuid
      @codeharbor_link = codeharbor_link
    end

    def execute
      response = self.class.connection.post @codeharbor_link.check_uuid_url do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@codeharbor_link.api_key}"
        req.body = {uuid: @uuid}.to_json
      end
      response_hash = JSON.parse(response.body, symbolize_names: true).slice(:uuid_found, :update_right)

      {error: false, message: message(response_hash[:uuid_found], response_hash[:update_right])}.merge(response_hash)
    rescue Faraday::Error, JSON::ParserError
      {error: true, message: I18n.t('exercises.export_codeharbor.error')}
    end

    private

    def message(task_found, update_right)
      if task_found
        update_right ? I18n.t('exercises.export_codeharbor.check.task_found') : I18n.t('exercises.export_codeharbor.check.task_found_no_right')
      else
        I18n.t('exercises.export_codeharbor.check.no_task')
      end
    end
  end
end
