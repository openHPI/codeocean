# frozen_string_literal: true

require 'rails_helper'

describe Admin::DashboardController do
  before { allow(controller).to receive(:current_user).and_return(build(:admin)) }

  describe 'GET #show' do
    describe 'with format HTML' do
      before { get :show }

      expect_status(200)
      expect_template(:show)
    end

    describe 'with format JSON' do
      before { get :show, format: :json }

      expect_json
      expect_status(200)
    end
  end
end
