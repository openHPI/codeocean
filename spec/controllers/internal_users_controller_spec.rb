require 'rails_helper'

describe InternalUsersController do
  let(:user) { FactoryGirl.build(:admin) }
  let!(:users) { FactoryGirl.create_pair(:teacher) }

  describe 'GET #activate' do
    let(:user) { InternalUser.create(FactoryGirl.attributes_for(:teacher)) }

    before(:each) do
      user.send(:setup_activation)
      user.save(validate: false)
    end

    context 'without a valid activation token' do
      before(:each) { get :activate, id: user.id }

      expect_redirect
    end

    context 'with an already activated user' do
      before(:each) do
        user.activate!
        get :activate, id: user.id, token: user.activation_token
      end

      expect_redirect
    end

    context 'with valid preconditions' do
      before(:each) { get :activate, id: user.id, token: user.activation_token }

      expect_assigns(user: InternalUser)
      expect_status(200)
      expect_template(:activate)
    end
  end

  describe 'PUT #activate' do
    let(:user) { InternalUser.create(FactoryGirl.attributes_for(:teacher)) }
    let(:password) { SecureRandom.hex }

    before(:each) do
      user.send(:setup_activation)
      user.save(validate: false)
      expect(user.activation_token).to be_present
    end

    context 'without a valid activation token' do
      before(:each) { put :activate, id: user.id }

      expect_redirect
    end

    context 'with an already activated user' do
      before(:each) do
        user.activate!
        put :activate, id: user.id, internal_user: {activation_token: user.activation_token, password: password, password_confirmation: password}
      end

      expect_redirect
    end

    context 'without a password' do
      before(:each) { put :activate, id: user.id, internal_user: {activation_token: user.activation_token} }

      expect_assigns(user: InternalUser)

      it 'builds a user with errors' do
        expect(assigns(:user).errors).to be_present
      end

      expect_template(:activate)
    end

    context 'without a valid password confirmation' do
      before(:each) { put :activate, id: user.id, internal_user: {activation_token: user.activation_token, password: password, password_confirmation: ''} }

      expect_assigns(user: InternalUser)

      it 'builds a user with errors' do
        expect(assigns(:user).errors).to be_present
      end

      expect_template(:activate)
    end

    context 'with valid preconditions' do
      before(:each) { put :activate, id: user.id, internal_user: {activation_token: user.activation_token, password: password, password_confirmation: password} }

      expect_assigns(user: InternalUser)

      it 'activates the user' do
        expect(assigns[:user]).to be_activated
      end

      expect_flash_message(:notice, :'internal_users.activate.success')
      expect_redirect
    end
  end

  describe 'POST #create' do
    before(:each) { allow(controller).to receive(:current_user).and_return(user) }

    context 'with a valid internal user' do
      let(:request) { proc { post :create, internal_user: FactoryGirl.attributes_for(:teacher) } }
      before(:each) { request.call }

      expect_assigns(user: InternalUser)

      it 'creates the internal user' do
        expect { request.call }.to change(InternalUser, :count).by(1)
      end

      it 'creates an inactive user' do
        expect(InternalUser.last).not_to be_activated
      end

      it 'sets up an activation token' do
        expect(InternalUser.last.activation_token).to be_present
      end

      it 'sends an activation email' do
        expect_any_instance_of(InternalUser).to receive(:send_activation_needed_email!)
        request.call
      end

      expect_redirect
    end

    context 'with an invalid internal user' do
      before(:each) { post :create, internal_user: {} }

      expect_assigns(user: InternalUser)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      delete :destroy, id: users.first.id
    end

    expect_assigns(user: InternalUser)

    it 'destroys the internal user' do
      expect { delete :destroy, id: InternalUser.last.id }.to change(InternalUser, :count).by(-1)
    end

    expect_redirect(:internal_users)
  end

  describe 'GET #edit' do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      get :edit, id: users.first.id
    end

    expect_assigns(user: InternalUser)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
    end

    expect_assigns(users: InternalUser.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      get :new
    end

    expect_assigns(user: InternalUser)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    before(:each) do
      allow(controller).to receive(:current_user).and_return(user)
      get :show, id: users.first.id
    end

    expect_assigns(user: InternalUser)
    expect_status(200)
    expect_template(:show)
  end

  describe 'PUT #update' do
    before(:each) { allow(controller).to receive(:current_user).and_return(user) }

    context 'with a valid internal user' do
      before(:each) { put :update, internal_user: FactoryGirl.attributes_for(:teacher), id: users.first.id }

      expect_assigns(user: InternalUser)
      expect_redirect
    end

    context 'with an invalid internal user' do
      before(:each) { put :update, internal_user: {email: ''}, id: users.first.id }

      expect_assigns(user: InternalUser)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
