# frozen_string_literal: true

require 'rails_helper'

describe ExecutionEnvironmentsController do
  let(:execution_environment) { FactoryBot.create(:ruby) }
  let(:user) { FactoryBot.create(:admin) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:copy_execution_environment_to_poseidon).and_return(nil)
  end

  describe 'POST #create' do
    before { allow(DockerClient).to receive(:image_tags).at_least(:once).and_return([]) }

    context 'with a valid execution environment' do
      let(:perform_request) { proc { post :create, params: {execution_environment: FactoryBot.build(:ruby).attributes} } }

      before { perform_request.call }

      expect_assigns(docker_images: Array)
      expect_assigns(execution_environment: ExecutionEnvironment)

      it 'creates the execution environment' do
        expect { perform_request.call }.to change(ExecutionEnvironment, :count).by(1)
      end

      it 'registers the execution environment with Poseidon' do
        expect(controller).to have_received(:copy_execution_environment_to_poseidon)
      end

      expect_redirect(ExecutionEnvironment.last)
    end

    context 'with an invalid execution environment' do
      before { post :create, params: {execution_environment: {}} }

      expect_assigns(execution_environment: ExecutionEnvironment)
      expect_status(200)
      expect_template(:new)

      it 'does not register the execution environment with Poseidon' do
        expect(controller).not_to have_received(:copy_execution_environment_to_poseidon)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: execution_environment.id} }

    expect_assigns(execution_environment: :execution_environment)

    it 'destroys the execution environment' do
      execution_environment = FactoryBot.create(:ruby)
      expect { delete :destroy, params: {id: execution_environment.id} }.to change(ExecutionEnvironment, :count).by(-1)
    end

    expect_redirect(:execution_environments)
  end

  describe 'GET #edit' do
    before do
      allow(DockerClient).to receive(:image_tags).at_least(:once).and_return([])
      get :edit, params: {id: execution_environment.id}
    end

    expect_assigns(docker_images: Array)
    expect_assigns(execution_environment: :execution_environment)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'POST #execute_command' do
    let(:command) { 'which ruby' }

    before do
      allow(DockerClient).to receive(:new).with(execution_environment: execution_environment).and_call_original
      allow_any_instance_of(DockerClient).to receive(:execute_arbitrary_command).with(command)
      post :execute_command, params: {command: command, id: execution_environment.id}
    end

    expect_assigns(docker_client: DockerClient)
    expect_assigns(execution_environment: :execution_environment)
    expect_json
    expect_status(200)
  end

  describe 'GET #index' do
    before do
      FactoryBot.create_pair(:ruby)
      get :index
    end

    expect_assigns(execution_environments: ExecutionEnvironment.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before do
      allow(DockerClient).to receive(:image_tags).at_least(:once).and_return([])
      get :new
    end

    expect_assigns(docker_images: Array)
    expect_assigns(execution_environment: ExecutionEnvironment)
    expect_status(200)
    expect_template(:new)
  end

  describe '#set_docker_images' do
    context 'when Docker is available' do
      let(:docker_images) { [1, 2, 3] }

      before do
        allow(DockerClient).to receive(:check_availability!).at_least(:once)
        allow(DockerClient).to receive(:image_tags).and_return(docker_images)
        controller.send(:set_docker_images)
      end

      expect_assigns(docker_images: :docker_images)
    end

    context 'when Docker is unavailable' do
      let(:error_message) { 'Docker is unavailable' }

      before do
        allow(DockerClient).to receive(:check_availability!).at_least(:once).and_raise(DockerClient::Error.new(error_message))
        controller.send(:set_docker_images)
      end

      it 'fails gracefully' do
        expect { controller.send(:set_docker_images) }.not_to raise_error
      end

      expect_assigns(docker_images: Array)
      expect_flash_message(:warning, :error_message)
    end
  end

  describe 'GET #shell' do
    before { get :shell, params: {id: execution_environment.id} }

    expect_assigns(execution_environment: :execution_environment)
    expect_status(200)
    expect_template(:shell)
  end

  describe 'GET #statistics' do
    before { get :statistics, params: {id: execution_environment.id} }

    expect_assigns(execution_environment: :execution_environment)
    expect_status(200)
    expect_template(:statistics)
  end

  describe 'GET #show' do
    before { get :show, params: {id: execution_environment.id} }

    expect_assigns(execution_environment: :execution_environment)
    expect_status(200)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid execution environment' do
      before do
        allow(DockerClient).to receive(:image_tags).at_least(:once).and_return([])
        allow(controller).to receive(:copy_execution_environment_to_poseidon).and_return(nil)
        put :update, params: {execution_environment: FactoryBot.attributes_for(:ruby), id: execution_environment.id}
      end

      expect_assigns(docker_images: Array)
      expect_assigns(execution_environment: ExecutionEnvironment)
      expect_redirect(:execution_environment)

      it 'updates the execution environment at Poseidon' do
        expect(controller).to have_received(:copy_execution_environment_to_poseidon)
      end
    end

    context 'with an invalid execution environment' do
      before { put :update, params: {execution_environment: {name: ''}, id: execution_environment.id} }

      expect_assigns(execution_environment: ExecutionEnvironment)
      expect_status(200)
      expect_template(:edit)

      it 'does not update the execution environment at Poseidon' do
        expect(controller).not_to have_received(:copy_execution_environment_to_poseidon)
      end
    end
  end

  describe '#synchronize_all_to_poseidon' do
    let(:execution_environments) { FactoryBot.build_list(:ruby, 3) }

    it 'copies all execution environments to Poseidon' do
      allow(ExecutionEnvironment).to receive(:all).and_return(execution_environments)

      execution_environments.each do |execution_environment|
        allow(execution_environment).to receive(:copy_to_poseidon).and_return(true)
      end

      post :synchronize_all_to_poseidon

      expect(execution_environments).to all(have_received(:copy_to_poseidon).once)
    end
  end
end
