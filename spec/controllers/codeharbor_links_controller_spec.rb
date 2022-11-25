# frozen_string_literal: true

require 'rails_helper'

describe CodeharborLinksController do
  render_views

  let(:user) { create(:teacher) }

  before do
    allow(CodeharborLinkPolicy::CODEHARBOR_CONFIG).to receive(:[]).with(:enabled).and_return(true)
    allow(CodeharborLinkPolicy::CODEHARBOR_CONFIG).to receive(:[]).with(:url).and_return('https://test.url')
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #new' do
    before do
      get :new
    end

    expect_http_status(:ok)
  end

  describe 'GET #edit' do
    let(:codeharbor_link) { create(:codeharbor_link, user:) }

    before { get :edit, params: {id: codeharbor_link.id} }

    expect_http_status(:ok)
  end

  describe 'POST #create' do
    let(:post_request) { post :create, params: {codeharbor_link: params} }
    let(:params) { {push_url: 'https://foo.bar/push', check_uuid_url: 'https://foo.bar/check', api_key: 'api_key'} }

    it 'creates a codeharbor_link' do
      expect { post_request }.to change(CodeharborLink, :count).by(1)
    end

    it 'redirects to user show' do
      expect(post_request).to redirect_to(user)
    end

    context 'with invalid params' do
      let(:params) { {push_url: '', check_uuid_url: '', api_key: ''} }

      it 'does not create a codeharbor_link' do
        expect { post_request }.not_to change(CodeharborLink, :count)
      end

      it 'redirects to user show' do
        post_request
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PUT #update' do
    let(:codeharbor_link) { create(:codeharbor_link, user:) }
    let(:put_request) { patch :update, params: {id: codeharbor_link.id, codeharbor_link: params} }
    let(:params) { {push_url: 'https://foo.bar/push', check_uuid_url: 'https://foo.bar/check', api_key: 'api_key'} }

    it 'updates push_url' do
      expect { put_request }.to change { codeharbor_link.reload.push_url }.to('https://foo.bar/push')
    end

    it 'updates check_uuid_url' do
      expect { put_request }.to change { codeharbor_link.reload.check_uuid_url }.to('https://foo.bar/check')
    end

    it 'updates api_key' do
      expect { put_request }.to change { codeharbor_link.reload.api_key }.to('api_key')
    end

    it 'redirects to user show' do
      expect(put_request).to redirect_to(user)
    end

    context 'with invalid params' do
      let(:params) { {push_url: '', check_uuid_url: '', api_key: ''} }

      it 'does not change codeharbor_link' do
        expect { put_request }.not_to(change { codeharbor_link.reload.attributes })
      end

      it 'redirects to user show' do
        put_request
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:codeharbor_link) { create(:codeharbor_link, user:) }
    let(:destroy_request) { delete :destroy, params: {id: codeharbor_link.id} }

    it 'deletes codeharbor_link' do
      expect { destroy_request }.to change(CodeharborLink, :count).by(-1)
    end

    it 'redirects to user show' do
      expect(destroy_request).to redirect_to(user)
    end
  end
end
