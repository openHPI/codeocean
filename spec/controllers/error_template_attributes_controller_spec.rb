# frozen_string_literal: true

require 'rails_helper'

describe ErrorTemplateAttributesController do
  let!(:error_template_attribute) { FactoryBot.create(:error_template_attribute) }
  let(:user) { FactoryBot.create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  it 'gets index' do
    get :index
    expect(response.status).to eq(200)
    expect(assigns(:error_template_attributes)).not_to be_nil
  end

  it 'gets new' do
    get :new
    expect(response.status).to eq(200)
  end

  it 'creates error_template_attribute' do
    expect { post :create, params: {error_template_attribute: {}} }.to change(ErrorTemplateAttribute, :count).by(1)
    expect(response).to redirect_to(error_template_attribute_path(assigns(:error_template_attribute)))
  end

  it 'shows error_template_attribute' do
    get :show, params: {id: error_template_attribute}
    expect(response.status).to eq(200)
  end

  it 'gets edit' do
    get :edit, params: {id: error_template_attribute}
    expect(response.status).to eq(200)
  end

  it 'updates error_template_attribute' do
    patch :update, params: {id: error_template_attribute, error_template_attribute: FactoryBot.attributes_for(:error_template_attribute)}
    expect(response).to redirect_to(error_template_attribute_path(assigns(:error_template_attribute)))
  end

  it 'destroys error_template_attribute' do
    expect { delete :destroy, params: {id: error_template_attribute} }.to change(ErrorTemplateAttribute, :count).by(-1)
    expect(response).to redirect_to(error_template_attributes_path)
  end
end
