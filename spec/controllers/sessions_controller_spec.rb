# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController do
  render_views

  let(:consumer) { create(:consumer) }

  describe 'POST #create' do
    let(:password) { attributes_for(:teacher)[:password] }
    let(:user) { InternalUser.create(user_attributes.merge(password:, consumer:)) }
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

    context 'without a valid absolute launch return presentation URL' do
      shared_examples 'a handled error' do
        it 'refuses the LTI launch' do
          allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true)
          expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_launch_presentation_return_url')).and_call_original
          post :create_through_lti, params: {oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, launch_presentation_return_url:}
        end
      end

      context 'with an empty URL' do
        let(:launch_presentation_return_url) { '' }

        it_behaves_like 'a handled error'
      end

      context 'with a relative URL' do
        let(:launch_presentation_return_url) { '/relative/url' }

        it_behaves_like 'a handled error'
      end
    end

    context 'without a valid absolute LIS Outcome service URL' do
      shared_examples 'a handled error' do
        it 'refuses the LTI launch' do
          allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true)
          expect(controller).to receive(:refuse_lti_launch).with(message: I18n.t('sessions.oauth.invalid_lis_outcome_service_url')).and_call_original
          post :create_through_lti, params: {oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, lis_outcome_service_url:}
        end
      end

      context 'with an empty URL' do
        let(:lis_outcome_service_url) { '' }

        it_behaves_like 'a handled error'
      end

      context 'with a relative URL' do
        let(:lis_outcome_service_url) { '/relative/url' }

        it_behaves_like 'a handled error'
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
      let(:perform_request) { post :create_through_lti, params: {custom_locale: locale, custom_token: exercise.token, oauth_consumer_key: consumer.oauth_key, oauth_nonce: nonce, oauth_signature: SecureRandom.hex, user_id: user.external_id, launch_presentation_return_url: 'https://example.org/', lis_outcome_service_url: 'https://example.org/'} }
      let(:user) { create(:external_user, consumer:) }

      before { allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:valid_request?).and_return(true) }

      it 'assigns the current user as @user' do
        perform_request
        expect(assigns(:user)).to be_an(ExternalUser)
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

      it 'persists LTI parameters' do
        expect(controller).to receive(:store_lti_session_data)
        perform_request
      end

      it 'updates the session' do
        expect(controller.session).to receive(:[]=).with(:locale, anything).and_call_original
        expect(controller.session).to receive(:[]=).with(:study_group_id, anything).and_call_original
        expect(controller.session).to receive(:[]=).with(:embed_options, anything).and_call_original
        expect(controller.session).to receive(:[]=).with(:return_to_url, implement_exercise_path(exercise)).and_call_original # Initial redirect by the controller
        expect(controller.session).to receive(:[]=).with(:return_to_url, nil).and_call_original # Clearing the URL as done by Sorcery
        expect(controller.session).to receive(:[]=).with(:return_to_url_notice, anything).and_call_original
        expect(controller.session).to receive(:[]=).with(:external_user_id, anything).and_call_original
        expect(controller.session).to receive(:[]=).with(:pair_programming, anything).and_call_original
        expect(controller.session).to receive(:[]=).with('flash', anything).twice.and_call_original
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
        expect(controller.session).to receive(:delete).with(:external_user_id)
        expect(controller.session).to receive(:delete).with(:study_group_id)
        expect(controller.session).to receive(:delete).with(:embed_options)
        expect(controller.session).to receive(:delete).with(:pg_id)
        expect(controller.session).to receive(:delete).with(:pair_programming)
        delete :destroy
      end

      it 'redirects to the root path' do
        expect(controller).to redirect_to(:root)
      end
    end
  end

  describe 'GET #destroy_through_lti' do
    shared_examples 'a successful request' do # rubocop:disable RSpec/SharedContext
      let(:perform_request) { proc { get :destroy_through_lti, params: {submission_id: submission.id} } }
      let(:submission) { create(:submission, exercise: create(:dummy)) }

      before do
        lti_parameter.save!
        allow(controller).to receive(:current_user).and_return(submission.contributor)
        perform_request.call
      end

      expect_http_status(:ok)
      expect_template(:destroy_through_lti)
    end

    context 'when a launch return presentation URL is provided' do
      context 'when a LIS Outcome service URL is provided' do
        let(:lti_parameter) { create(:lti_parameter, external_user: submission.contributor) }

        it_behaves_like 'a successful request'
      end

      context 'when no LIS Outcome service URL is provided' do
        let(:lti_parameter) { create(:lti_parameter, :without_outcome_service_url, external_user: submission.contributor) }

        it_behaves_like 'a successful request'
      end
    end

    context 'when no launch return presentation URL is provided' do
      context 'when a LIS Outcome service URL is provided' do
        let(:lti_parameter) { create(:lti_parameter, :without_return_url, external_user: submission.contributor) }

        it_behaves_like 'a successful request'
      end

      context 'when no LIS Outcome service URL is provided' do
        let(:lti_parameter) { create(:lti_parameter, :without_return_url, :without_outcome_service_url, external_user: submission.contributor) }

        it_behaves_like 'a successful request'
      end
    end
  end

  describe 'GET #new' do
    context 'when no user is logged in' do
      before do
        allow(controller).to receive_messages(set_sentry_context: nil, current_user: nil)

        get :new
      end

      expect_http_status(:ok)
      expect_template(:new)
    end

    context 'when a user is already logged in' do
      before do
        allow(controller).to receive_messages(set_sentry_context: nil, current_user: build(:teacher))

        get :new
      end

      expect_flash_message(:alert, :'shared.already_signed_in')
      expect_redirect(:root)
    end
  end
end
