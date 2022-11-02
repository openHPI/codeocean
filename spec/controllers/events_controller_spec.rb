# frozen_string_literal: true

require 'rails_helper'

describe EventsController do
  render_views

  let(:user) { create(:admin) }
  let(:exercise) { create(:fibonacci) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid event' do
      let(:perform_request) { proc { post :create, params: {event: {category: 'foo', data: 'bar', exercise_id: exercise.id, file_id: exercise.files[0].id}} } }

      before { perform_request.call }

      expect_assigns(event: Event)

      it 'creates the Event' do
        expect { perform_request.call }.to change(Event, :count).by(1)
      end

      expect_http_status(:created)
    end

    context 'with an invalid event' do
      before { post :create, params: {event: {exercise_id: 847_482}} }

      expect_assigns(event: Event)
      expect_http_status(:unprocessable_entity)
    end

    context 'with no event' do
      before { post :create }

      expect_http_status(:unprocessable_entity)
    end
  end
end
