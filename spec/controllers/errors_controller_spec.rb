require 'rails_helper'

describe ErrorsController do
  let(:error) { FactoryGirl.create(:error) }
  let(:execution_environment) { error.execution_environment }
  let(:user) { FactoryGirl.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid error' do
      let(:request) { proc { post :create, execution_environment_id: FactoryGirl.build(:error).execution_environment.id, error: FactoryGirl.attributes_for(:error), format: :json } }

      context 'when a hint can be matched' do
        let(:hint) { FactoryGirl.build(:ruby_syntax_error).message }

        before(:each) do
          expect_any_instance_of(Whistleblower).to receive(:generate_hint).and_return(hint)
          request.call
        end

        expect_assigns(execution_environment: :execution_environment)

        it 'does not create the error' do
          allow_any_instance_of(Whistleblower).to receive(:generate_hint).and_return(hint)
          expect { request.call }.not_to change(Error, :count)
        end

        it 'returns the hint' do
          expect(response.body).to eq({hint: hint}.to_json)
        end

        expect_json
        expect_status(200)
      end

      context 'when no hint can be matched' do
        before(:each) do
          expect_any_instance_of(Whistleblower).to receive(:generate_hint).and_return(nil)
          request.call
        end

        expect_assigns(execution_environment: :execution_environment)

        it 'creates the error' do
          allow_any_instance_of(Whistleblower).to receive(:generate_hint)
          expect { request.call }.to change(Error, :count).by(1)
        end

        expect_json
        expect_status(201)
      end
    end

    context 'with an invalid error' do
      before(:each) { post :create, execution_environment_id: FactoryGirl.build(:error).execution_environment.id, error: {}, format: :json }

      expect_assigns(error: Error)
      expect_json
      expect_status(422)
    end
  end

  describe 'GET #index' do
    before(:all) { FactoryGirl.create_pair(:error) }
    before(:each) { get :index, execution_environment_id: execution_environment.id }

    expect_assigns(execution_environment: :execution_environment)

    it 'aggregates errors by message' do
      expect(assigns(:errors).length).to eq(1)
    end

    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #show' do
    before(:each) { get :show, execution_environment_id: execution_environment.id, id: error.id }

    expect_assigns(error: :error)
    expect_assigns(execution_environment: :execution_environment)
    expect_status(200)
    expect_template(:show)
  end
end
