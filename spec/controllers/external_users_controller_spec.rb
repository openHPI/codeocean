# frozen_string_literal: true

require 'rails_helper'

describe ExternalUsersController do
  render_views

  let(:user) { build(:admin) }
  let!(:users) { create_pair(:external_user) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'GET #index' do
    before { get :index }

    expect_assigns(users: ExternalUser.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #show' do
    before { get :show, params: {id: users.first.id} }

    expect_assigns(user: ExternalUser)
    expect_http_status(:ok)
    expect_template(:show)
  end
end
