# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PingController do
  render_views

  describe 'index' do
    before { allow(Runner.strategy_class).to receive(:health).and_return(true) }

    it 'returns the wanted page and answer with HTTP Status 200' do
      get :index

      expect(response).to have_http_status :ok
    end
  end
end
