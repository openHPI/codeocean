# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ApiController do
  controller(described_class) do
    def index
      head :ok
    end
  end

  before do
    routes.draw do
      get 'index' => 'api/api#index'
    end
  end

  describe 'authentication' do
    context 'with valid token' do
      it 'allows the request' do
        request.headers['Authorization'] = 'Bearer supersecrettoken'

        get :index

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid token' do
      it 'returns 401 Unauthorized' do
        request.headers['Authorization'] = 'Bearer invalid_token'

        get :index

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without token' do
      it 'returns 401 Unauthorized' do
        get :index

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without the INTERNAL_API_TOKEN being set' do
      it 'returns 401 Unauthorized' do
        allow(ENV)
          .to receive(:fetch)
          .with('INTERNAL_API_TOKEN', nil)
          .and_return(nil)

        request.headers['Authorization'] = "Bearer #{ENV.fetch('INTERNAL_API_TOKEN', nil)}"
        get :index

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
