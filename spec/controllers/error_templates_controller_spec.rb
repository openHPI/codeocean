# frozen_string_literal: true

require 'rails_helper'

describe ErrorTemplatesController do
  render_views

  let!(:error_template) { create(:error_template) }
  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  it 'gets index' do
    get :index
    expect(response).to have_http_status(:ok)
    expect(assigns(:error_templates)).not_to be_nil
  end

  it 'gets new' do
    get :new
    expect(response).to have_http_status(:ok)
  end

  it 'creates error_template' do
    expect { post :create, params: {error_template: {execution_environment_id: error_template.execution_environment.id}} }.to change(ErrorTemplate, :count).by(1)
    expect(response).to redirect_to(error_template_path(assigns(:error_template)))
  end

  it 'shows error_template' do
    get :show, params: {id: error_template}
    expect(response).to have_http_status(:ok)
  end

  it 'gets edit' do
    get :edit, params: {id: error_template}
    expect(response).to have_http_status(:ok)
  end

  it 'updates error_template' do
    patch :update, params: {id: error_template, error_template: attributes_for(:error_template)}
    expect(response).to redirect_to(error_template_path(assigns(:error_template)))
  end

  it 'destroys error_template' do
    expect { delete :destroy, params: {id: error_template} }.to change(ErrorTemplate, :count).by(-1)
    expect(response).to redirect_to(error_templates_path)
  end
end
