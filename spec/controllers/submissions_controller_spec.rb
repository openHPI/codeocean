require 'rails_helper'

describe SubmissionsController do
  let(:submission) { FactoryBot.create(:submission) }
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    before(:each) do
      controller.request.accept = 'application/json'
    end

    context 'with a valid submission' do
      let(:exercise) { FactoryBot.create(:hello_world) }
      let(:request) { proc { post :create, format: :json, submission: FactoryBot.attributes_for(:submission, exercise_id: exercise.id) } }
      before(:each) { request.call }

      expect_assigns(submission: Submission)

      it 'creates the submission' do
        expect { request.call }.to change(Submission, :count).by(1)
      end

      expect_json
      expect_status(201)
    end

    context 'with an invalid submission' do
      before(:each) { post :create, submission: {} }

      expect_assigns(submission: Submission)
      expect_json
      expect_status(422)
    end
  end

  describe 'GET #download_file' do
    context 'with an invalid filename' do
      before(:each) { get :download_file, filename: SecureRandom.hex, id: submission.id }

      expect_status(404)
    end

    context 'with a valid filename' do
      let(:submission) { FactoryBot.create(:submission, exercise: FactoryBot.create(:audio_video)) }
      before(:each) { get :download_file, filename: file.name_with_extension, id: submission.id }

      context 'for a binary file' do
        let(:file) { submission.collect_files.detect { |file| file.file_type.file_extension == '.mp4' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('application/octet-stream')
        expect_status(200)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to eq("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end

      context 'for a non-binary file' do
        let(:file) { submission.collect_files.detect { |file| file.file_type.file_extension == '.js' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('text/javascript')
        expect_status(200)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to eq("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end
    end
  end

  describe 'GET #index' do
    before(:all) { FactoryBot.create_pair(:submission) }
    before(:each) { get :index }

    expect_assigns(submissions: Submission.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #render_file' do
    let(:file) { submission.files.first }

    context 'with an invalid filename' do
      before(:each) { get :render_file, filename: SecureRandom.hex, id: submission.id }

      expect_status(404)
    end

    context 'with a valid filename' do
      let(:submission) { FactoryBot.create(:submission, exercise: FactoryBot.create(:audio_video)) }
      before(:each) { get :render_file, filename: file.name_with_extension, id: submission.id }

      context 'for a binary file' do
        let(:file) { submission.collect_files.detect { |file| file.file_type.file_extension == '.mp4' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('application/octet-stream')
        expect_status(200)

        it 'renders the file content' do
          expect(response.body).to eq(file.native_file.read)
        end
      end

      context 'for a non-binary file' do
        let(:file) { submission.collect_files.detect { |file| file.file_type.file_extension == '.js' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('text/javascript')
        expect_status(200)

        it 'renders the file content' do
          expect(response.body).to eq(file.content)
        end
      end
    end
  end

  describe 'GET #run' do
    let(:filename) { submission.collect_files.detect(&:main_file?).name_with_extension }
    let(:request) { get :run, filename: filename, id: submission.id }

    before(:each) do
      expect_any_instance_of(ActionController::Live::SSE).to receive(:write).at_least(3).times
    end

    context 'when no errors occur during execution' do
      before(:each) do
        expect_any_instance_of(DockerClient).to receive(:execute_run_command).with(submission, filename).and_return({})
        request
      end

      pending("todo")
    end

    context 'when an error occurs during execution' do
      let(:stderr) { "undefined method `foo' for main:Object (NoMethodError)" }

      before(:each) do
        expect_any_instance_of(DockerClient).to receive(:execute_run_command).with(submission, filename).and_yield(:stderr, stderr)
      end

      after(:each) { request }

      context 'when the error is covered by a hint' do
        let(:hint) { "Your object 'main' of class 'Object' does not understand the method 'foo'." }

        before(:each) do
          expect_any_instance_of(Whistleblower).to receive(:generate_hint).with(stderr).and_return(hint)
        end

        it 'does not store the error' do
          pending("no server sent events used right now")
          expect(Error).not_to receive(:create)
        end
      end

      context 'when the error is not covered by a hint' do
        before(:each) do
          expect_any_instance_of(Whistleblower).to receive(:generate_hint).with(stderr)
        end

        it 'stores the error' do
          pending("no server sent events used right now")
          expect(Error).to receive(:create).with(execution_environment_id: submission.exercise.execution_environment_id, message: stderr)
        end
      end
    end
  end

  describe 'GET #show' do
    before(:each) { get :show, id: submission.id }

    expect_assigns(submission: :submission)
    expect_status(200)
    expect_template(:show)
  end

  describe 'GET #show.json' do
    # Render views requested in controller tests in order to get json responses
    # https://github.com/rails/jbuilder/issues/32
    render_views

    before(:each) { get :show, id: submission.id, format: :json }
    expect_assigns(submission: :submission)
    expect_status(200)

    [:render, :run, :test].each do |action|
      describe "##{action}_url" do
        let(:url) { JSON.parse(response.body).with_indifferent_access.fetch("#{action}_url") }

        it "starts like the #{action} path" do
          filename = File.basename(__FILE__)
          expect(url).to start_with(Rails.application.routes.url_helpers.send(:"#{action}_submission_path", submission, filename).sub(filename, ''))
        end

        it 'ends with a placeholder' do
          expect(url).to end_with(Submission::FILENAME_URL_PLACEHOLDER)
        end
      end
    end

    [:score, :stop].each do |action|
      describe "##{action}_url" do
        let(:url) { JSON.parse(response.body).with_indifferent_access.fetch("#{action}_url") }

        it "corresponds to the #{action} path" do
          expect(url).to eq(Rails.application.routes.url_helpers.send(:"#{action}_submission_path", submission))
        end
      end
    end
  end

  describe 'GET #score' do
    let(:request) { proc { get :score, id: submission.id } }
    before(:each) { request.call }

    pending("todo: mock puma webserver or encapsulate tubesock call (Tubesock::HijackNotAvailable)")
  end

  describe 'POST #stop' do
    let(:request) { proc { post :stop, container_id: CONTAINER.id, id: submission.id } }

    context 'when the container can be found' do
      before(:each) do
        expect(Docker::Container).to receive(:get).and_return(CONTAINER)
        #expect(Rails.logger).to receive(:debug).at_least(:once).and_call_original
        request.call
      end

      it 'renders nothing' do
        expect(response.body).to be_blank
      end

      expect_status(200)
    end

    context 'when the container cannot be found' do
      before(:each) do
        expect(Docker::Container).to receive(:get).and_raise(Docker::Error::NotFoundError)
        request.call
      end

      it 'renders nothing' do
        expect(response.body).to be_blank
      end

      expect_status(200)
    end
  end

  describe 'GET #test' do
    let(:filename) { submission.collect_files.detect(&:teacher_defined_test?).name_with_extension }
    let(:output) { {} }

    before(:each) do
      expect_any_instance_of(DockerClient).to receive(:execute_test_command).with(submission, filename)
      get :test, filename: filename, id: submission.id
    end

    pending("todo")
  end

  describe '#with_server_sent_events' do
    let(:response) { ActionController::TestResponse.new }
    before(:each) { allow(controller).to receive(:response).and_return(response) }

    context 'when no error occurs' do
      after(:each) { controller.send(:with_server_sent_events) }

      it 'uses server-sent events' do
        expect(ActionController::Live::SSE).to receive(:new).and_call_original
      end

      it "writes a 'start' event" do
        allow_any_instance_of(ActionController::Live::SSE).to receive(:write)
        expect_any_instance_of(ActionController::Live::SSE).to receive(:write).with(nil, event: 'start')
      end

      it "writes a 'close' event" do
        allow_any_instance_of(ActionController::Live::SSE).to receive(:write)
        expect_any_instance_of(ActionController::Live::SSE).to receive(:write).with({code: 200}, event: 'close')
      end

      it 'closes the stream' do
        expect_any_instance_of(ActionController::Live::SSE).to receive(:close).and_call_original
      end
    end

    context 'when an error occurs' do
      after(:each) { controller.send(:with_server_sent_events) { fail } }

      it 'uses server-sent events' do
        expect(ActionController::Live::SSE).to receive(:new).and_call_original
      end

      it "writes a 'start' event" do
        allow_any_instance_of(ActionController::Live::SSE).to receive(:write)
        expect_any_instance_of(ActionController::Live::SSE).to receive(:write).with(nil, event: 'start')
      end

      it "writes a 'close' event" do
        allow_any_instance_of(ActionController::Live::SSE).to receive(:write)
        expect_any_instance_of(ActionController::Live::SSE).to receive(:write).with({code: 500}, event: 'close')
      end

      it 'closes the stream' do
        expect_any_instance_of(ActionController::Live::SSE).to receive(:close).and_call_original
      end
    end
  end
end
