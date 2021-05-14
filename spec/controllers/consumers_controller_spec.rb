# frozen_string_literal: true

require 'rails_helper'

describe ConsumersController do
  let(:consumer) { FactoryBot.create(:consumer) }
  let(:user) { FactoryBot.create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid consumer' do
      let(:perform_request) { proc { post :create, params: {consumer: FactoryBot.attributes_for(:consumer)} } }

      before { perform_request.call }

      expect_assigns(consumer: Consumer)

      it 'creates the consumer' do
        expect { perform_request.call }.to change(Consumer, :count).by(1)
      end

      expect_redirect(Consumer.last)
    end

    context 'with an invalid consumer' do
      before { post :create, params: {consumer: {}} }

      expect_assigns(consumer: Consumer)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: consumer.id} }

    expect_assigns(consumer: Consumer)

    it 'destroys the consumer' do
      consumer = FactoryBot.create(:consumer)
      expect { delete :destroy, params: {id: consumer.id} }.to change(Consumer, :count).by(-1)
    end

    expect_redirect(:consumers)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: consumer.id} }

    expect_assigns(consumer: Consumer)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before do
      FactoryBot.create_pair(:consumer)
      get :index
    end

    expect_assigns(consumers: Consumer.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before { get :new }

    expect_assigns(consumer: Consumer)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    before { get :show, params: {id: consumer.id} }

    expect_assigns(consumer: :consumer)
    expect_status(200)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid consumer' do
      before { put :update, params: {consumer: FactoryBot.attributes_for(:consumer), id: consumer.id} }

      expect_assigns(consumer: Consumer)
      expect_redirect(:consumer)
    end

    context 'with an invalid consumer' do
      before { put :update, params: {consumer: {name: ''}, id: consumer.id} }

      expect_assigns(consumer: Consumer)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
