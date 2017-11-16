require 'rails_helper'

describe Admin::DashboardController do
  before(:each) { allow(controller).to receive(:current_user).and_return(FactoryBot.build(:admin)) }

  describe 'GET #show' do
    describe 'with format HTML' do
      before(:each) { get :show }

      expect_status(200)
      expect_template(:show)
    end

    describe 'with format JSON' do
      before(:each) { get :show, format: :json }

      expect_json
      expect_status(200)
    end
  end
end
