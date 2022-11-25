# frozen_string_literal: true

require 'rails_helper'

describe ApplicationController do
  render_views

  describe '#current_user' do
    context 'with an external user' do
      let(:external_user) { create(:external_user) }

      before { session[:external_user_id] = external_user.id }

      it 'returns the external user' do
        expect(controller.current_user).to eq(external_user)
      end
    end

    context 'without an external user' do
      let(:internal_user) { create(:teacher) }

      before { login_user(internal_user) }

      it 'returns the internal user' do
        expect(controller.current_user).to eq(internal_user)
      end
    end
  end

  describe '#render_not_authorized' do
    before do
      allow(controller).to receive(:welcome) { controller.send(:render_not_authorized) }
      get :welcome
    end

    expect_flash_message(:alert, I18n.t('application.not_authorized'))
    expect_redirect(:root)
  end

  describe '#render_not_found' do
    before do
      allow(controller).to receive(:welcome) { controller.send(:render_not_found) }
      login_user(user) if defined?(user)
      get :welcome
    end

    expect_flash_message(:alert, I18n.t('application.not_authorized'))
    expect_redirect(:root)

    context 'with an admin' do
      let(:user) { create(:admin) }

      expect_flash_message(:alert, I18n.t('application.not_found'))
    end

    context 'with a teacher' do
      let(:user) { create(:teacher) }

      expect_flash_message(:alert, I18n.t('application.not_authorized'))
    end
  end

  describe '#switch_locale' do
    let(:locale) { :de }

    context 'when specifying a locale' do
      before { allow(session).to receive(:[]=).at_least(:once) }

      context "when using the 'custom_locale' parameter" do
        it 'overwrites the session' do
          expect(session).to receive(:[]=).with(:locale, locale)
          get :welcome, params: {custom_locale: locale}
        end
      end

      context "when using the 'locale' parameter" do
        it 'overwrites the session' do
          expect(session).to receive(:[]=).with(:locale, locale)
          get :welcome, params: {locale:}
        end
      end
    end

    context "with a 'locale' value in the session" do
      it 'sets this locale' do
        session[:locale] = locale
        # The around block first sets the default language and then the language requested
        expect(I18n).to receive(:locale=).with(I18n.default_locale)
        expect(I18n).to receive(:locale=).with(locale)
        get :welcome
      end
    end

    context "without a 'locale' value in the session" do
      it 'sets the default locale' do
        expect(session[:locale]).to be_blank
        expect(I18n).to receive(:locale=).with(I18n.default_locale).at_least(:once)
        get :welcome
      end
    end
  end

  describe 'GET #welcome' do
    before { get :welcome }

    expect_http_status(:ok)
    expect_template(:welcome)
  end
end
