# frozen_string_literal: true

require 'rails_helper'

describe ExecutionEnvironmentsController do
  render_views

  let(:execution_environment) { create(:ruby) }
  let(:user) { create(:admin) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(Runner.strategy_class).to receive(:available_images).and_return([])
  end

  describe 'POST #create' do
    context 'with a valid execution environment' do
      let(:perform_request) { proc { post :create, params: {execution_environment: build(:ruby, pool_size: 1).attributes} } }

      before do
        allow(Rails.env).to receive(:test?).and_return(false, true)
        allow(Runner.strategy_class).to receive(:sync_environment).and_return(true)
        runner = instance_double Runner
        allow(Runner).to receive(:for).and_return(runner)
        allow(runner).to receive(:execute_command).and_return({})
        perform_request.call
      end

      expect_assigns(docker_images: Array)
      expect_assigns(execution_environment: ExecutionEnvironment)

      it 'creates the execution environment' do
        expect { perform_request.call }.to change(ExecutionEnvironment, :count).by(1)
      end

      it 'registers the execution environment with the runner management' do
        expect(Runner.strategy_class).to have_received(:sync_environment)
      end

      expect_redirect(ExecutionEnvironment.last)
    end

    context 'with an invalid execution environment' do
      before do
        allow(Runner.strategy_class).to receive(:sync_environment).and_return(true)
        allow(Rails.env).to receive(:test?).and_return(false, true)
        post :create, params: {execution_environment: {}}
      end

      expect_assigns(execution_environment: ExecutionEnvironment)
      expect_http_status(:ok)
      expect_template(:new)

      it 'does not register the execution environment with the runner management' do
        expect(Runner.strategy_class).not_to have_received(:sync_environment)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(Runner.strategy_class).to receive(:remove_environment).and_return(true)
      delete :destroy, params: {id: execution_environment.id}
    end

    expect_assigns(execution_environment: :execution_environment)

    it 'destroys the execution environment' do
      execution_environment = create(:ruby)
      expect { delete :destroy, params: {id: execution_environment.id} }.to change(ExecutionEnvironment, :count).by(-1)
    end

    it 'removes the execution environment from the runner management' do
      expect(Runner.strategy_class).to have_received(:remove_environment)
    end

    expect_redirect(:execution_environments)
  end

  describe 'GET #edit' do
    before do
      get :edit, params: {id: execution_environment.id}
    end

    expect_assigns(docker_images: Array)
    expect_assigns(execution_environment: :execution_environment)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'POST #execute_command' do
    let(:command) { 'which ruby' }

    before do
      runner = instance_double Runner
      allow(Runner).to receive(:for).with(user, execution_environment).and_return runner
      allow(runner).to receive(:execute_command).and_return({})
      post :execute_command, params: {command:, id: execution_environment.id}
    end

    expect_assigns(execution_environment: :execution_environment)
    expect_json
    expect_http_status(:ok)
  end

  describe 'GET #index' do
    before do
      create_pair(:ruby)
      get :index
    end

    expect_assigns(execution_environments: ExecutionEnvironment.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before do
      get :new
    end

    expect_assigns(docker_images: Array)
    expect_assigns(execution_environment: ExecutionEnvironment)
    expect_http_status(:ok)
    expect_template(:new)
  end

  describe '#set_docker_images' do
    context 'when Docker is available' do
      let(:docker_images) { %w[image:one image:two image:three] }

      before do
        allow(Runner).to receive(:strategy_class).and_return Runner::Strategy::DockerContainerPool
        allow(Runner::Strategy::DockerContainerPool).to receive(:available_images).and_return(docker_images)
        controller.send(:set_docker_images)
      end

      expect_assigns(docker_images: :docker_images)
    end

    context 'when Docker is unavailable' do
      let(:error_message) { 'Docker is unavailable' }

      before do
        allow(Runner).to receive(:strategy_class).and_return Runner::Strategy::DockerContainerPool
        allow(Runner::Strategy::DockerContainerPool).to receive(:available_images).and_raise(Runner::Error::InternalServerError.new(error_message))
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
    expect_http_status(:ok)
    expect_template(:shell)
  end

  describe 'GET #statistics' do
    before { get :statistics, params: {id: execution_environment.id} }

    expect_assigns(execution_environment: :execution_environment)
    expect_http_status(:ok)
    expect_template(:statistics)
  end

  describe 'GET #show' do
    before { get :show, params: {id: execution_environment.id} }

    expect_assigns(execution_environment: :execution_environment)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid execution environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false, true)
        allow(Runner.strategy_class).to receive(:sync_environment).and_return(true)
        runner = instance_double Runner
        allow(Runner).to receive(:for).and_return(runner)
        allow(runner).to receive(:execute_command).and_return({})
        put :update, params: {execution_environment: attributes_for(:ruby, pool_size: 1), id: execution_environment.id}
      end

      expect_assigns(docker_images: Array)
      expect_assigns(execution_environment: ExecutionEnvironment)
      expect_redirect(:execution_environment)

      it 'updates the execution environment at the runner management' do
        expect(Runner.strategy_class).to have_received(:sync_environment)
      end
    end

    context 'with an invalid execution environment' do
      before do
        allow(Runner.strategy_class).to receive(:sync_environment).and_return(true)
        allow(Rails.env).to receive(:test?).and_return(true, false, true)
        put :update, params: {execution_environment: {name: ''}, id: execution_environment.id}
      end

      expect_assigns(execution_environment: ExecutionEnvironment)
      expect_http_status(:ok)
      expect_template(:edit)

      it 'does not update the execution environment at the runner management' do
        expect(Runner.strategy_class).not_to have_received(:sync_environment)
      end
    end
  end

  describe '#sync_all_to_runner_management' do
    let(:execution_environments) { %i[ruby java python].map {|environment| create(environment) } }
    let(:outdated_execution_environments) { %i[node_js html].map {|environment| build_stubbed(environment) } }

    let(:codeocean_config) { instance_double(CodeOcean::Config) }
    let(:runner_management_config) { {runner_management: {enabled: true, strategy: :poseidon}} }

    before do
      # Ensure to reset the memorized helper
      Runner.instance_variable_set :@strategy_class, nil
      allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
      allow(codeocean_config).to receive(:read).and_return(runner_management_config)
    end

    it 'copies all execution environments to the runner management' do
      allow(Runner::Strategy::Poseidon).to receive(:environments).and_return(outdated_execution_environments)
      expect(Runner::Strategy::Poseidon).to receive(:environments).once

      execution_environments.each do |execution_environment|
        allow(Runner::Strategy::Poseidon).to receive(:sync_environment).with(execution_environment).and_return(true)
        expect(Runner::Strategy::Poseidon).to receive(:sync_environment).with(execution_environment).once
        expect(Runner::Strategy::Poseidon).not_to receive(:remove_environment).with(execution_environment)
      end

      outdated_execution_environments.each do |execution_environment|
        allow(Runner::Strategy::Poseidon).to receive(:remove_environment).with(execution_environment).and_return(true)
        expect(Runner::Strategy::Poseidon).to receive(:remove_environment).with(execution_environment).once
        expect(Runner::Strategy::Poseidon).not_to receive(:sync_environment).with(execution_environment)
      end

      post :sync_all_to_runner_management
    end
  end
end
