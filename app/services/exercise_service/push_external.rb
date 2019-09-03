# frozen_string_literal: true

module ExerciseService
  class PushExternal < ServiceBase
    CODEHARBOR_PUSH_LINK = Rails.env.production? ? 'https://codeharbor.openhpi.de/import_exercise' : 'http://localhost:3001/import_exercise'
    def initialize(zip:, codeharbor_link:)
      @zip = zip
      @codeharbor_link = codeharbor_link
    end

    def execute
      oauth2_client = OAuth2::Client.new(@codeharbor_link.client_id, @codeharbor_link.client_secret, site: CODEHARBOR_PUSH_LINK)
      oauth2_token = @codeharbor_link[:oauth2token]
      token = OAuth2::AccessToken.from_hash(oauth2_client, access_token: oauth2_token)
      body = @zip.string
      begin
        token.post(
          CODEHARBOR_PUSH_LINK,
          body: body,
          headers: {'Content-Type' => 'application/zip', 'Content-Length' => body.length.to_s}
        )
        return nil
      rescue StandardError => e
        return e
      end
    end
  end
end
