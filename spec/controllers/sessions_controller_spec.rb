require 'rails_helper'

describe SessionsController do
  let(:consumer) { FactoryGirl.create(:consumer) }

  describe 'POST #create' do
    let(:password) { user_attributes[:password] }
    let(:user) { InternalUser.create(user_attributes) }
    let(:user_attributes) { FactoryGirl.attributes_for(:teacher) }

    context 'with valid credentials' do
      before(:each) do
        user.activate!
        post :create, email: user.email, password: password, remember_me: 1
      end

      expect_flash_message(:notice, :'sessions.create.success')
      expect_redirect
    end

    context 'with invalid credentials' do
      before(:each) { post :create, email: user.email, password: '', remember_me: 1 }

      expect_flash_message(:danger, :'sessions.create.failure')
      expect_template(:new)
    end
  end

  describe 'POST #create_through_lti' do
    let(:exercise) { FactoryGirl.create(:dummy) }
    let(:nonce) { SecureRandom.hex }

    context 'without OAuth parameters' do
      it 'refuses the LTI launch' do
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.missing_parameters')).and_call_original
        post :create_through_lti
      end
    end

    context 'without a valid consumer key' do
      it 'refuses the LTI launch' do
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_consumer')).and_call_original
        post :create_through_lti, oauth_consumer_key: SecureRandom.hex, oauth_signature: SecureRandom.hex
      end
    end

    context 'with an invalid OAuth signature' do
      it 'refuses the LTI launch' do
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_signature')).and_call_original
        post :create_through_lti, oauth_consumer_key: consumer.oauth_key, oauth_signature: SecureRandom.hex
      end
    end

    context 'without a unique OAuth nonce' do
      it 'refuses the LTI launch' do
        expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true)
        expect(NonceStore).to receive(:has?).with(nonce).and_return(true)
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.used_nonce')).and_call_original
        post :create_through_lti, oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex
      end
    end

    context 'without a valid exercise token' do
      it 'refuses the LTI launch' do
        expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true)
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_exercise_token')).and_call_original
        post :create_through_lti, custom_token: '', oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex
      end
    end

    context 'with valid launch parameters' do
      let(:request) { post :create_through_lti, custom_token: exercise.token, oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, user_id: user.external_id }
      let(:user) { FactoryGirl.create(:external_user, consumer_id: consumer.id) }
      before(:each) { expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true) }

      it 'assigns the current user' do
        request
        expect(assigns(:current_user)).to be_an(ExternalUser)
        expect(session[:external_user_id]).to eq(user.id)
      end

      it 'assigns the exercise' do
        request
        expect(assigns(:exercise)).to eq(exercise)
      end

      it 'stores LTI parameters in the session' do
        expect(controller).to receive(:store_lti_session_data)
        request
      end

      it 'stores the OAuth nonce' do
        expect(controller).to receive(:store_nonce).with(nonce)
        request
      end

      context 'when LTI outcomes are supported' do
        before(:each) do
          expect(controller).to receive(:lti_outcome_service?).and_return(true)
          request
        end

        it 'displays a flash message' do
          expect(flash[:notice]).to eq(I18n.t('sessions.create_through_lti.session_with_outcome', consumer: consumer))
        end
      end

      context 'when LTI outcomes are not supported' do
        before(:each) do
          expect(controller).to receive(:lti_outcome_service?).and_return(false)
          request
        end

        it 'displays a flash message' do
          expect(flash[:notice]).to eq(I18n.t('sessions.create_through_lti.session_without_outcome', consumer: consumer))
        end
      end

      it 'redirects to the requested exercise' do
        request
        expect(controller).to redirect_to(implement_exercise_path(exercise.id))
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { double }
    before(:each) { expect(controller).to receive(:current_user).at_least(:once).and_return(user) }

    context 'with an internal user' do
      before(:each) do
        allow(user).to receive(:external?).and_return(false)
        allow(user).to receive(:forget_me!)
        delete :destroy
      end

      it 'performs a logout' do
        expect(controller).to receive(:logout)
        delete :destroy
      end

      it 'redirects to the root path' do
        expect(controller).to redirect_to(:root)
      end
    end

    context 'with an external user' do
      before(:each) do
        allow(user).to receive(:external?).and_return(true)
        delete :destroy
      end

      it 'clears the session' do
        expect(controller).to receive(:clear_lti_session_data)
        delete :destroy
      end

      it 'redirects to the root path' do
        expect(controller).to redirect_to(:root)
      end
    end
  end

  describe 'GET #destroy_through_lti' do
    let(:request) { proc { get :destroy_through_lti, consumer_id: consumer.id, submission_id: submission.id } }
    let(:submission) { FactoryGirl.create(:submission, exercise: FactoryGirl.create(:dummy)) }

    before(:each) do
      session[:consumer_id] = consumer.id
      session[:lti_parameters] = {}
    end

    before(:each) { request.call }

    it 'clears the session' do
      expect(controller).to receive(:clear_lti_session_data)
      request.call
    end

    expect_status(200)
    expect_template(:destroy_through_lti)
  end

  describe 'GET #new' do
    context 'when no user is logged in' do
      before(:each) do
        expect(controller).to receive(:current_user).and_return(nil)
        get :new
      end

      expect_status(200)
      expect_template(:new)
    end

    context 'when a user is already logged in' do
      before(:each) do
        expect(controller).to receive(:current_user).and_return(FactoryGirl.build(:teacher))
        get :new
      end

      expect_redirect
    end
  end
end
