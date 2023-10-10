# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PingController do
  render_views

  describe 'GET #index' do
    before do
      allow(Runner.strategy_class).to receive(:health).and_return(true)
      get :index
    end

    expect_json
    expect_http_status(:ok)
  end
end
