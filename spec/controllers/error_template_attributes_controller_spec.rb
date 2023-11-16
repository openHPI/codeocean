# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorTemplateAttributesController do
  render_views

  let!(:error_template_attribute) { create(:error_template_attribute) }
  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'GET #index' do
    before { get :index }

    expect_assigns(error_template_attributes: ErrorTemplateAttribute.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before { get :new }

    expect_http_status(:ok)
    expect_template(:new)
  end

  describe 'POST #create' do
    before { post :create, params: {error_template_attribute: {}} }

    expect_assigns(error_template_attribute: ErrorTemplateAttribute)

    it 'creates the error template attribute' do
      expect { post :create, params: {error_template_attribute: {}} }.to change(ErrorTemplateAttribute, :count).by(1)
    end

    expect_redirect { error_template_attribute_path(assigns(:error_template_attribute)) }
  end

  describe 'GET #show' do
    before { get :show, params: {id: error_template_attribute} }

    expect_assigns(error_template_attribute: ErrorTemplateAttribute)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: error_template_attribute} }

    expect_assigns(error_template_attribute: ErrorTemplateAttribute)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'PATCH #update' do
    before { patch :update, params: {id: error_template_attribute, error_template_attribute: attributes_for(:error_template_attribute)} }

    expect_assigns(error_template_attribute: ErrorTemplateAttribute)

    expect_redirect { error_template_attribute }
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: error_template_attribute} }

    expect_assigns(error_template_attribute: ErrorTemplateAttribute)

    it 'destroys the error template attribute' do
      error_template_attribute = create(:error_template_attribute)
      expect { delete :destroy, params: {id: error_template_attribute} }.to change(ErrorTemplateAttribute, :count).by(-1)
    end

    expect_redirect(:error_template_attributes)
  end
end
