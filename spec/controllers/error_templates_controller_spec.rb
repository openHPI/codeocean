require 'rails_helper'

describe ErrorTemplatesController do
  let!(:error_template) { FactoryBot.create(:error_template) }
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  it "should get index" do
    get :index
    expect(response.status).to eq(200)
    expect(assigns(:error_templates)).not_to be_nil
  end

  it "should get new" do
    get :new
    expect(response.status).to eq(200)
  end

  it "should create error_template" do
    expect { post :create, params: {error_template: { execution_environment_id: error_template.execution_environment.id } } }.to change(ErrorTemplate, :count).by(1)
    expect(response).to redirect_to(error_template_path(assigns(:error_template)))
  end

  it "should show error_template" do
    get :show, params: { id: error_template }
    expect(response.status).to eq(200)
  end

  it "should get edit" do
    get :edit, params: { id: error_template }
    expect(response.status).to eq(200)
  end

  it "should update error_template" do
    patch :update, params: { id: error_template, error_template: FactoryBot.attributes_for(:error_template) }
    expect(response).to redirect_to(error_template_path(assigns(:error_template)))
  end

  it "should destroy error_template" do
    expect { delete :destroy, params: { id: error_template } }.to change(ErrorTemplate, :count).by(-1)
    expect(response).to redirect_to(error_templates_path)
  end
end
