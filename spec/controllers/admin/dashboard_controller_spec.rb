# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardController do
  render_views

  let(:codeocean_config) { instance_double(CodeOcean::Config) }
  let(:runner_management_config) { {runner_management: {enabled: false}} }

  before do
    allow(controller).to receive(:current_user).and_return(build(:admin))

    allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
    allow(codeocean_config).to receive(:read).and_return(runner_management_config)
  end

  describe 'GET #show' do
    describe 'with format HTML' do
      before { get :show }

      expect_http_status(:ok)
      expect_template(:show)
    end

    describe 'with format JSON' do
      before { get :show, format: :json }

      expect_json
      expect_http_status(:ok)
    end
  end
end
