require 'rails_helper'

describe TeamsController do
  let(:team) { FactoryGirl.create(:team) }
  let(:user) { FactoryGirl.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid team' do
      let(:request) { Proc.new { post :create, team: FactoryGirl.attributes_for(:team) } }
      before(:each) { request.call }

      expect_assigns(team: Team)

      it 'creates the team' do
        expect { request.call }.to change(Team, :count).by(1)
      end

      expect_redirect
    end

    context 'with an invalid team' do
      before(:each) { post :create, team: {} }

      expect_assigns(team: Team)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before(:each) { delete :destroy, id: team.id }

    expect_assigns(team: Team)

    it 'destroys the team' do
      team = FactoryGirl.create(:team)
      expect { delete :destroy, id: team.id }.to change(Team, :count).by(-1)
    end

    expect_redirect(:teams)
  end

  describe 'GET #edit' do
    before(:each) { get :edit, id: team.id }

    expect_assigns(team: Team)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before(:all) { FactoryGirl.create_pair(:team) }
    before(:each) { get :index }

    expect_assigns(teams: Team.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before(:each) { get :new }

    expect_assigns(team: Team)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    before(:each) { get :show, id: team.id }

    expect_assigns(team: :team)
    expect_status(200)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid team' do
      before(:each) { put :update, team: FactoryGirl.attributes_for(:team), id: team.id }

      expect_assigns(team: Team)
      expect_redirect
    end

    context 'with an invalid team' do
      before(:each) { put :update, team: {name: ''}, id: team.id }

      expect_assigns(team: Team)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
