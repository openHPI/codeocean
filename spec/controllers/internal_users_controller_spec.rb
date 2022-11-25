# frozen_string_literal: true

require 'rails_helper'

describe InternalUsersController do
  render_views

  let(:user) { create(:admin) }

  describe 'GET #activate' do
    let(:user) { InternalUser.create(attributes_for(:teacher)) }

    before do
      user.send(:setup_activation)
      user.save(validate: false)
    end

    context 'without a valid activation token' do
      before { get :activate, params: {id: user.id} }

      expect_redirect(:root)
    end

    context 'with an already activated user' do
      before do
        user.activate!
        get :activate, params: {id: user.id, token: user.activation_token}
      end

      expect_redirect(:root)
    end

    context 'with valid preconditions' do
      before { get :activate, params: {id: user.id, token: user.activation_token} }

      expect_assigns(user: InternalUser)
      expect_http_status(:ok)
      expect_template(:activate)
    end
  end

  describe 'PUT #activate' do
    let(:user) { InternalUser.create(build(:teacher).attributes) }
    let(:password) { SecureRandom.hex }

    before do
      user.send(:setup_activation)
      user.save(validate: false)
    end

    it 'adds an activation token' do
      expect(user.activation_token).to be_present
    end

    context 'without a valid activation token' do
      before { put :activate, params: {id: user.id} }

      expect_redirect(:root)
    end

    context 'with an already activated user' do
      before do
        user.activate!
        put :activate, params: {id: user.id, internal_user: {activation_token: user.activation_token, password:, password_confirmation: password}}
      end

      expect_redirect(:root)
    end

    context 'without a password' do
      before { put :activate, params: {id: user.id, internal_user: {activation_token: user.activation_token}} }

      expect_assigns(user: InternalUser)

      it 'builds a user with errors' do
        expect(assigns(:user).errors).to be_present
      end

      expect_template(:activate)
    end

    context 'without a valid password confirmation' do
      before { put :activate, params: {id: user.id, internal_user: {activation_token: user.activation_token, password:, password_confirmation: ''}} }

      expect_assigns(user: InternalUser)

      it 'builds a user with errors' do
        expect(assigns(:user).errors).to be_present
      end

      expect_template(:activate)
    end

    context 'with valid preconditions' do
      before { put :activate, params: {id: user.id, internal_user: {activation_token: user.activation_token, password:, password_confirmation: password}} }

      expect_assigns(user: InternalUser)

      it 'activates the user' do
        expect(assigns[:user]).to be_activated
      end

      expect_flash_message(:notice, :'internal_users.activate.success')
      expect_redirect(:sign_in)
    end
  end

  describe 'POST #create' do
    before { allow(controller).to receive(:current_user).and_return(user) }

    context 'with a valid internal user' do
      let(:perform_request) { proc { post :create, params: {internal_user: build(:teacher).attributes} } }

      before { perform_request.call }

      expect_assigns(user: InternalUser)

      it 'creates the internal user' do
        expect { perform_request.call }.to change(InternalUser, :count).by(1)
      end

      it 'creates an inactive user' do
        expect(InternalUser.last).not_to be_activated
      end

      it 'sets up an activation token' do
        expect(InternalUser.last.activation_token).to be_present
      end

      it 'sends an activation email' do
        expect_any_instance_of(InternalUser).to receive(:send_activation_needed_email!)
        perform_request.call
      end

      expect_redirect(InternalUser.last)
    end

    context 'with an invalid internal user' do
      before { post :create, params: {internal_user: {invalid_attribute: 'a string'}} }

      expect_assigns(user: InternalUser)
      expect_http_status(:ok)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    let(:second_user) { create(:teacher) }
    let(:third_user) { create(:teacher) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      delete :destroy, params: {id: second_user.id}
    end

    expect_assigns(user: InternalUser)

    it 'destroys the internal user' do
      # We want to ensure that the user is activated and valid before proceeding
      third_user.activate!
      expect { delete :destroy, params: {id: third_user.id} }.to change(InternalUser, :count).by(-1)
    end

    expect_redirect(:internal_users)
  end

  describe 'GET #edit' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      get :edit, params: {id: user.id}
    end

    expect_assigns(user: InternalUser)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'GET #forgot_password' do
    context 'when no user is logged in' do
      before do
        allow(controller).to receive(:set_sentry_context).and_return(nil)

        allow(controller).to receive(:current_user).and_return(nil)
        get :forgot_password
      end

      expect_http_status(:ok)
      expect_template(:forgot_password)
    end

    context 'when a user is already logged in' do
      before do
        allow(controller).to receive(:set_sentry_context).and_return(nil)

        allow(controller).to receive(:current_user).and_return(user)
        get :forgot_password
      end

      expect_flash_message(:alert, :'shared.already_signed_in')
      expect_redirect(:root)
    end
  end

  describe 'POST #forgot_password' do
    context 'with an email address' do
      let(:perform_request) { proc { post :forgot_password, params: {email: user.email} } }

      before { perform_request.call }

      it 'delivers instructions to reset the password' do
        allow(InternalUser).to receive(:where).and_return([user])
        expect(user).to receive(:deliver_reset_password_instructions!)
        perform_request.call
      end

      expect_redirect(:root)
    end

    context 'without an email address' do
      before { post :forgot_password }

      expect_http_status(:ok)
      expect_template(:forgot_password)
    end
  end

  describe 'GET #index' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
    end

    expect_assigns(users: InternalUser.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      get :new
    end

    expect_assigns(user: InternalUser)
    expect_http_status(:ok)
    expect_template(:new)
  end

  describe 'GET #reset_password' do
    context 'without a valid password reset token' do
      before { get :reset_password, params: {id: user.id} }

      expect_redirect(:root)
    end

    context 'with a valid password reset token' do
      before do
        user.deliver_reset_password_instructions!
        get :reset_password, params: {id: user.id, token: user.reset_password_token}
      end

      expect_assigns(user: :user)
      expect_http_status(:ok)
      expect_template(:reset_password)
    end
  end

  describe 'PUT #reset_password' do
    before { user.deliver_reset_password_instructions! }

    context 'without a valid password reset token' do
      before { put :reset_password, params: {id: user.id} }

      expect_redirect(:root)
    end

    context 'with a valid password reset token' do
      let(:password) { 'foo' }

      context 'with a matching password confirmation' do
        let(:perform_request) { proc { put :reset_password, params: {internal_user: {password:, password_confirmation: password}, id: user.id, token: user.reset_password_token} } }

        before { perform_request.call }

        expect_assigns(user: :user)

        context 'with a weak password' do
          let(:password) { 'foo' }

          it 'does not change the password' do
            expect { perform_request.call }.not_to change { user.reload.crypted_password }
            expect(InternalUser.authenticate(user.email, password)).not_to eq(user)
          end

          expect_http_status(:ok)
          expect_template(:reset_password)
        end

        context 'with a strong password' do
          let(:password) { SecureRandom.hex(128) }

          it 'changes the password' do
            expect { perform_request.call }.not_to change { user.reload.crypted_password }
            expect(InternalUser.authenticate(user.email, password)).to eq(user)
          end

          expect_redirect(:sign_in)
        end
      end

      context 'without a matching password confirmation' do
        before do
          put :reset_password, params: {internal_user: {password:, password_confirmation: ''}, id: user.id, token: user.reset_password_token}
        end

        expect_assigns(user: :user)
        expect_http_status(:ok)
        expect_template(:reset_password)
      end
    end
  end

  describe 'GET #show' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      get :show, params: {id: user.id}
    end

    expect_assigns(user: InternalUser)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'PUT #update' do
    before { allow(controller).to receive(:current_user).and_return(user) }

    context 'with a valid internal user' do
      before { put :update, params: {internal_user: attributes_for(:teacher), id: user.id} }

      expect_assigns(user: InternalUser)
      expect_redirect { user }
    end

    context 'with an invalid internal user' do
      before { put :update, params: {internal_user: {email: ''}, id: user.id} }

      expect_assigns(user: InternalUser)
      expect_http_status(:ok)
      expect_template(:edit)
    end
  end
end
