require 'rails_helper'

describe ExternalUsersController do
  let(:user) { FactoryGirl.build(:admin) }
  let!(:users) { FactoryGirl.create_pair(:external_user) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'GET #index' do
    before(:each) { get :index }

    expect_assigns(users: ExternalUser.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #show' do
    before(:each) { get :show, id: users.first.id }

    expect_assigns(user: ExternalUser)
    expect_status(200)
    expect_template(:show)
  end
end
