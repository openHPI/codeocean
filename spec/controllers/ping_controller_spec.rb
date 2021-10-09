# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PingController, type: :controller do
  describe 'index' do
    it 'returns the wanted page and answer with HTTP Status 200' do
      get :index

      expect(response).to have_http_status :ok
    end
  end
end
