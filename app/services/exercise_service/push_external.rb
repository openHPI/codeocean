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
        return nil if response.success?
        return I18n.t('exercises.export_codeharbor.not_authorized') if response.status == 401

        handle_error(message: response.body)
      rescue Faraday::ServerError => e
        handle_error(error: e, message: I18n.t('exercises.export_codeharbor.server_error'))
      rescue StandardError => e
        handle_error(error: e, message: I18n.t('exercises.export_codeharbor.generic_error'))
      end
    end

    private

    def handle_error(message:, error: nil)
      Sentry.capture_exception(error) if error.present?
      ERB::Util.html_escape(message)
    end
  end
end
