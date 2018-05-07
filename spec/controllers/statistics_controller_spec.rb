require 'rails_helper'

describe StatisticsController do
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  [:show, :graphs].each do |route|
    describe "GET ##{route}" do
      before(:each) { get route }

      expect_status(200)
      expect_template(route)
    end
  end

  [:user_activity_history, :rfc_activity_history].each do |route|
    describe "GET ##{route}" do
      before(:each) { get route }

      expect_status(200)
      expect_template(:activity_history)
    end
  end

  [:show, :user_activity, :user_activity_history, :rfc_activity, :rfc_activity_history].each do |route|
    describe "GET ##{route}.json" do
      before(:each) { get route, format: :json }

      expect_status(200)
      expect_json
    end
  end

end
