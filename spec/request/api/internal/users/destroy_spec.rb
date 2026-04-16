# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DELETE Users API', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:headers) { {'Authorization' => 'Bearer supersecrettoken'} }

  describe 'DELETE /api/internal/users' do
    it 'soft deletes a user' do
      user = create(:external_user, external_id: '123456')

      freeze_time

      expect { delete '/api/internal/users/123456', headers: headers }
        .to change { user.reload.deleted_at }.to(Time.zone.now)
    end

    it 'returns an error if the user is not found' do
      delete '/api/internal/users/123456',
        headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
