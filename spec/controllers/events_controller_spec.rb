require 'rails_helper'

describe EventsController do
  let(:user) { FactoryBot.create(:admin) }
  let(:exercise) {FactoryBot.create(:fibonacci)}
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid event' do
      let(:request) { proc { post :create, event: {category: 'foo', data: 'bar', exercise_id: exercise.id, file_id: exercise.files[0].id} } }
      before(:each) { request.call }

      expect_assigns(event: Event)

      it 'creates the Event' do
        expect { request.call }.to change(Event, :count).by(1)
      end

      expect_status(201)
    end

    context 'with an invalid event' do
      before(:each) { post :create, event: {exercise_id: 847482} }
      expect_assigns(event: Event)
      expect_status(422)
    end

    context 'with no event' do
      before(:each) { post :create }
      expect_status(422)
    end
  end
end
