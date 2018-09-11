require 'rails_helper'

describe ErrorTemplateAttributesController do
  let!(:error_template_attribute) { FactoryBot.create(:error_template_attribute) }
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  it "should get index" do
    get :index
    expect(response.status).to eq(200)
    expect(assigns(:error_template_attributes)).not_to be_nil
  end

  it "should get new" do
    get :new
    expect(response.status).to eq(200)
  end

  it "should create error_template_attribute" do
    expect { post :create, error_template_attribute: {  } }.to change(ErrorTemplateAttribute, :count).by(1)
    expect(response).to redirect_to(error_template_attribute_path(assigns(:error_template_attribute)))
  end

  it "should show error_template_attribute" do
    get :show, id: error_template_attribute
    expect(response.status).to eq(200)
  end

  it "should get edit" do
    get :edit, id: error_template_attribute
    expect(response.status).to eq(200)
  end

  it "should update error_template_attribute" do
    patch :update, id: error_template_attribute, error_template_attribute: {  }
    expect(response).to redirect_to(error_template_attribute_path(assigns(:error_template_attribute)))
  end

  it "should destroy error_template_attribute" do
    expect { delete :destroy, id: error_template_attribute }.to change(ErrorTemplateAttribute, :count).by(-1)
    expect(response).to redirect_to(error_template_attributes_path)
  end
end
