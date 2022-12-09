# frozen_string_literal: true

require 'rails_helper'

describe SessionsController do
  render_views

  let(:consumer) { create(:consumer) }

  describe 'POST #create' do
    let(:password) { attributes_for(:teacher)[:password] }
    let(:user) { InternalUser.create(user_attributes.merge(password:)) }
    let(:user_attributes) { build(:teacher).attributes }

    context 'with valid credentials' do
      before do
        user.activate!
        post :create, params: {email: user.email, password:, remember_me: 1}
      end

      expect_flash_message(:notice, :'sessions.create.success')
      expect_redirect(:root)
    end

    context 'with invalid credentials' do
      before { post :create, params: {email: user.email, password: '', remember_me: 1} }

      expect_flash_message(:danger, :'sessions.create.failure')
      expect_template(:new)
    end
  end

  describe 'POST #create_through_lti' do
    let(:exercise) { create(:dummy) }
    let(:exercise2) { create(:dummy) }
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
        post :create_through_lti, params: {oauth_consumer_key: SecureRandom.hex, oauth_signature: SecureRandom.hex}
      end
    end

    context 'with an invalid OAuth signature' do
      it 'refuses the LTI launch' do
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_signature')).and_call_original
        post :create_through_lti, params: {oauth_consumer_key: consumer.oauth_key, oauth_signature: SecureRandom.hex}
      end
    end

    context 'without a unique OAuth nonce' do
      it 'refuses the LTI launch' do
        allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true)
        allow(NonceStore).to receive(:has?).with(nonce).and_return(true)
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.used_nonce')).and_call_original
        post :create_through_lti, params: {oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex}
      end
    end

    context 'without a valid exercise token' do
      it 'refuses the LTI launch' do
        allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true)
        expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_exercise_token')).and_call_original
        post :create_through_lti, params: {custom_token: '', oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, user_id: '123'}
      end
    end

    context 'with valid launch parameters' do
      let(:locale) { :de }
      let(:perform_request) { post :create_through_lti, params: {custom_locale: locale, custom_token: exercise.token, oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, user_id: user.external_id} }
      let(:user) { create(:external_user, consumer_id: consumer.id) }

      before { allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true) }

      it 'assigns the current user' do
        perform_request
        expect(assigns(:current_user)).to be_an(ExternalUser)
        expect(session[:external_user_id]).to eq(user.id)
      end

      it 'sets the specified locale' do
        expect(controller).to receive(:switch_locale).and_call_original
        i18n = class_double(I18n, locale:)
        allow(I18n).to receive(:locale=).with(I18n.default_locale).and_call_original
        allow(I18n).to receive(:locale=).with(locale).and_return(i18n)
        perform_request
        expect(i18n.locale.to_sym).to eq(locale)
      end

      it 'assigns the exercise' do
        perform_request
        expect(assigns(:exercise)).to eq(exercise)
      end

      it 'stores LTI parameters in the session' do
        # Todo replace session with lti_parameter /should be done already
        expect(controller).to receive(:store_lti_session_data)
        perform_request
      end

      it 'stores the OAuth nonce' do
        expect(controller).to receive(:store_nonce).with(nonce)
        perform_request
      end

      context 'when LTI outcomes are supported' do
        # The expected message should be localized in the requested localization
        let(:message) { I18n.t('sessions.create_through_lti.session_with_outcome', consumer:, locale:) }

        before do
          allow(controller).to receive(:lti_outcome_service?).and_return(true)
          perform_request
        end

        expect_flash_message(:notice, :message)
      end

      context 'when LTI outcomes are not supported' do
        # The expected message should be localized in the requested localization
        let(:message) { I18n.t('sessions.create_through_lti.session_without_outcome', consumer:, locale:) }

        before do
          allow(controller).to receive(:lti_outcome_service?).and_return(false)
          perform_request
        end

        expect_flash_message(:notice, :message)
      end

      it 'redirects to the requested exercise' do
        perform_request
        expect(controller).to redirect_to(implement_exercise_path(exercise.id))
      end

      it 'redirects to recommended exercise if requested token of proxy exercise' do
        create(:proxy_exercise, exercises: [exercise])
        post :create_through_lti, params: {custom_locale: locale, custom_token: ProxyExercise.first.token, oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, user_id: user.external_id}
        expect(controller).to redirect_to(implement_exercise_path(exercise.id))
      end

      it 'recommends only exercises who are 1 degree more complicated than what user has seen' do
        # dummy user has no exercises finished, therefore his highest difficulty is 0
        create(:proxy_exercise, exercises: [exercise, exercise2])
        exercise.expected_difficulty = 3
        exercise.save
        exercise2.expected_difficulty = 1
        exercise2.save
        post :create_through_lti, params: {custom_locale: locale, custom_token: ProxyExercise.first.token, oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, user_id: user.external_id}
        expect(controller).to redirect_to(implement_exercise_path(exercise2.id))
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { double }

    before do
      allow(controller).to receive(:set_sentry_context).and_return(nil)
      allow(controller).to receive(:current_user).at_least(:once).and_return(user)
    end

    context 'with an internal user' do
      before do
        allow(user).to receive(:external_user?).and_return(false)
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
      before do
        allow(user).to receive(:external_user?).and_return(true)
        delete :destroy
      end

      it 'clears the session' do
        # Todo replace session with lti_parameter /should be done already
        expect(controller).to receive(:clear_lti_session_data)
        delete :destroy
      end

      it 'redirects to the root path' do
        expect(controller).to redirect_to(:root)
      end
    end
  end

  describe 'GET #destroy_through_lti' do
    let(:perform_request) { proc { get :destroy_through_lti, params: {submission_id: submission.id} } }
    let(:submission) { create(:submission, exercise: create(:dummy)) }

    before do
      # Todo replace session with lti_parameter
      # Todo create LtiParameter Object
      # session[:lti_parameters] = {}
      allow(controller).to receive(:current_user).and_return(submission.user)
      perform_request.call
    end

    it 'clears the session' do
      # Todo replace session with lti_parameter /should be done already
      expect(controller).to receive(:clear_lti_session_data)
      perform_request.call
    end

    expect_http_status(:ok)
    expect_template(:destroy_through_lti)
  end

  describe 'GET #new' do
    context 'when no user is logged in' do
      before do
        allow(controller).to receive(:set_sentry_context).and_return(nil)

        allow(controller).to receive(:current_user).and_return(nil)
        get :new
      end

      expect_http_status(:ok)
      expect_template(:new)
    end

    context 'when a user is already logged in' do
      before do
        allow(controller).to receive(:set_sentry_context).and_return(nil)

        allow(controller).to receive(:current_user).and_return(build(:teacher))
        get :new
      end

      expect_flash_message(:alert, :'shared.already_signed_in')
      expect_redirect(:root)
    end
  end
end
