require 'rails_helper'

describe ApplicationController do
  describe '#current_user' do
    context 'with an external user' do
      let(:external_user) { FactoryGirl.create(:external_user) }
      before(:each) { session[:external_user_id] = external_user.id }

      it 'returns the external user' do
        expect(controller.current_user).to eq(external_user)
      end
    end

    context 'without an external user' do
      let(:internal_user) { FactoryGirl.create(:teacher) }
      before(:each) { login_user(internal_user) }

      it 'returns the internal user' do
        expect(controller.current_user).to eq(internal_user)
      end
    end
  end

  describe '#render_not_authorized' do
    let(:render_not_authorized) { controller.send(:render_not_authorized) }

    it 'displays a flash message' do
      expect(controller).to receive(:redirect_to)
      render_not_authorized
      expect(flash[:danger]).to eq(I18n.t('application.not_authorized'))
    end

    it 'redirects to the root URL' do
      expect(controller).to receive(:redirect_to).with(:root)
      render_not_authorized
    end
  end

  describe 'GET #welcome' do
    before(:each) { get :welcome }

    expect_status(200)
    expect_template(:welcome)
  end
end
