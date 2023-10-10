# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorTemplatesController do
  render_views

  let!(:error_template) { create(:error_template) }
  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'GET #index' do
    before { get :index }

    expect_assigns(error_templates: ErrorTemplate.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before { get :new }

    expect_http_status(:ok)
    expect_template(:new)
  end

  describe 'POST #create' do
    before { post :create, params: {error_template: {execution_environment_id: error_template.execution_environment.id}} }

    expect_assigns(error_template: ErrorTemplate)

    it 'creates the error template' do
      expect { post :create, params: {error_template: {execution_environment_id: error_template.execution_environment.id}} }.to change(ErrorTemplate, :count).by(1)
    end

    expect_redirect { error_template_path(assigns(:error_template)) }
  end

  describe 'GET #show' do
    before { get :show, params: {id: error_template} }

    expect_assigns(error_template: ErrorTemplate)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: error_template} }

    expect_assigns(error_template: ErrorTemplate)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'PATCH #update' do
    before { patch :update, params: {id: error_template, error_template: attributes_for(:error_template)} }

    expect_assigns(error_template: ErrorTemplate)

    expect_redirect { error_template }
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: error_template} }

    expect_assigns(error_template: ErrorTemplate)

    it 'destroys the error template' do
      error_template = create(:error_template)
      expect { delete :destroy, params: {id: error_template} }.to change(ErrorTemplate, :count).by(-1)
    end

    expect_redirect { error_template }
  end
end
