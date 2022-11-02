# frozen_string_literal: true

require 'rails_helper'

describe StatisticsController do
  render_views

  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  %i[show graphs].each do |route|
    describe "GET ##{route}" do
      before { get route }

      expect_http_status(:ok)
      expect_template(route)
    end
  end

  %i[user_activity_history rfc_activity_history].each do |route|
    describe "GET ##{route}" do
      before { get route }

      expect_http_status(:ok)
      expect_template(:activity_history)
    end
  end

  %i[show user_activity user_activity_history rfc_activity rfc_activity_history].each do |route|
    describe "GET ##{route}.json" do
      before { get route, format: :json }

      expect_http_status(:ok)
      expect_json
    end
  end
end
