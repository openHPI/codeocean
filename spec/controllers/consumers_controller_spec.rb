# frozen_string_literal: true

require 'rails_helper'

describe ConsumersController do
  render_views

  let(:consumer) { create(:consumer) }
  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid consumer' do
      let(:perform_request) { proc { post :create, params: {consumer: build(:consumer, name: 'New Consumer').attributes} } }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(consumer: Consumer)
        expect_redirect(Consumer.last)
      end

      it 'creates the consumer' do
        expect { perform_request.call }.to change(Consumer, :count).by(1)
      end
    end

    context 'with an invalid consumer' do
      before { post :create, params: {consumer: {}} }

      expect_assigns(consumer: Consumer)
      expect_http_status(:ok)
      expect_template(:new)
    end

    context 'with a duplicated consumer' do
      let(:perform_request) { proc { post :create, params: {consumer: build(:consumer).attributes} } }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(consumer: Consumer)
        expect_http_status(:ok)
        expect_template(:new)
      end

      it 'does not create a new consumer' do
        expect { perform_request.call }.not_to change(Consumer, :count)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: consumer.id} }

    expect_assigns(consumer: Consumer)

    it 'destroys the consumer' do
      consumer = create(:consumer)
      expect { delete :destroy, params: {id: consumer.id} }.to change(Consumer, :count).by(-1)
    end

    expect_redirect(:consumers)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: consumer.id} }

    expect_assigns(consumer: Consumer)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before do
      create_pair(:consumer)
      get :index
    end

    expect_assigns(consumers: Consumer.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before { get :new }

    expect_assigns(consumer: Consumer)
    expect_http_status(:ok)
    expect_template(:new)
  end

  describe 'GET #show' do
    before { get :show, params: {id: consumer.id} }

    expect_assigns(consumer: :consumer)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid consumer' do
      before { put :update, params: {consumer: attributes_for(:consumer), id: consumer.id} }

      expect_assigns(consumer: Consumer)
      expect_redirect(:consumer)
    end

    context 'with an invalid consumer' do
      before { put :update, params: {consumer: {name: ''}, id: consumer.id} }

      expect_assigns(consumer: Consumer)
      expect_http_status(:ok)
      expect_template(:edit)
    end
  end
end
