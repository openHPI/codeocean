# frozen_string_literal: true

require 'rails_helper'

describe SubmissionsController do
  let(:submission) { FactoryBot.create(:submission) }
  let(:user) { FactoryBot.create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    before do
      controller.request.accept = 'application/json'
    end

    context 'with a valid submission' do
      let(:exercise) { FactoryBot.create(:hello_world) }
      let(:perform_request) { proc { post :create, format: :json, params: {submission: FactoryBot.attributes_for(:submission, exercise_id: exercise.id)} } }

      before { perform_request.call }

      expect_assigns(submission: Submission)

      it 'creates the submission' do
        expect { perform_request.call }.to change(Submission, :count).by(1)
      end

      expect_json
      expect_status(201)
    end

    context 'with an invalid submission' do
      before { post :create, params: {submission: {}} }

      expect_assigns(submission: Submission)
      expect_json
      expect_status(422)
    end
  end

  describe 'GET #download_file' do
    context 'with an invalid filename' do
      before { get :download_file, params: {filename: SecureRandom.hex, id: submission.id} }

      expect_status(404)
    end

    context 'with a valid binary filename' do
      let(:submission) { FactoryBot.create(:submission, exercise: FactoryBot.create(:sql_select)) }

      before { get :download_file, params: {filename: file.name_with_extension, id: submission.id} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.name == 'exercise' && file.file_type.file_extension == '.sql' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('application/octet-stream')
        expect_status(200)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end
    end

    context 'with a valid filename' do
      let(:submission) { FactoryBot.create(:submission, exercise: FactoryBot.create(:audio_video)) }

      before { get :download_file, params: {filename: file.name_with_extension, id: submission.id} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.mp4' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('video/mp4')
        expect_status(200)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end

      context 'with a non-binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.js' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('text/javascript')
        expect_status(200)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end
    end
  end

  describe 'GET #index' do
    before do
      FactoryBot.create_pair(:submission)
      get :index
    end

    expect_assigns(submissions: Submission.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #render_file' do
    let(:file) { submission.files.first }

    context 'with an invalid filename' do
      before { get :render_file, params: {filename: SecureRandom.hex, id: submission.id} }

      expect_status(404)
    end

    context 'with a valid filename' do
      let(:submission) { FactoryBot.create(:submission, exercise: FactoryBot.create(:audio_video)) }

      before { get :render_file, params: {filename: file.name_with_extension, id: submission.id} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.mp4' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('video/mp4')
        expect_status(200)

        it 'renders the file content' do
          expect(response.body).to eq(file.native_file.read)
        end
      end

      context 'with a non-binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.js' } }

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
    let(:perform_request) { get :run, params: {filename: filename, id: submission.id} }

    before do
      allow_any_instance_of(ActionController::Live::SSE).to receive(:write).at_least(3).times
    end

    context 'when no errors occur during execution' do
      before do
        allow_any_instance_of(DockerClient).to receive(:execute_run_command).with(submission, filename).and_return({})
        perform_request
      end

      pending('todo')
    end
  end

  describe 'GET #show' do
    before { get :show, params: {id: submission.id} }

    expect_assigns(submission: :submission)
    expect_status(200)
    expect_template(:show)
  end

  describe 'GET #show.json' do
    # Render views requested in controller tests in order to get json responses
    # https://github.com/rails/jbuilder/issues/32
    render_views

    before { get :show, params: {id: submission.id}, format: :json }

    expect_assigns(submission: :submission)
    expect_status(200)

    %i[render run test].each do |action|
      describe "##{action}_url" do
        let(:url) { JSON.parse(response.body).with_indifferent_access.fetch("#{action}_url") }

        it "starts like the #{action} path" do
          filename = File.basename(__FILE__)
          expect(url).to start_with(Rails.application.routes.url_helpers.send(:"#{action}_submission_path", submission, filename).sub(filename, ''))
        end

        it 'ends with a placeholder' do
          expect(url).to end_with("#{Submission::FILENAME_URL_PLACEHOLDER}.json")
        end
      end
    end

    describe '#score_url' do
      let(:url) { JSON.parse(response.body).with_indifferent_access.fetch('score_url') }

      it 'corresponds to the score path' do
        expect(url).to eq(Rails.application.routes.url_helpers.score_submission_path(submission, format: :json))
      end
    end
  end

  describe 'GET #score' do
    let(:perform_request) { proc { get :score, params: {id: submission.id} } }

    before { perform_request.call }

    pending('todo: mock puma webserver or encapsulate tubesock call (Tubesock::HijackNotAvailable)')
  end

  describe 'GET #test' do
    let(:filename) { submission.collect_files.detect(&:teacher_defined_assessment?).name_with_extension }
    let(:output) { {} }

    before do
      allow_any_instance_of(DockerClient).to receive(:execute_test_command).with(submission, filename)
      get :test, params: {filename: filename, id: submission.id}
    end

    pending('todo')
  end

  describe '#with_server_sent_events' do
    let(:response) { ActionDispatch::TestResponse.new }

    before { allow(controller).to receive(:response).and_return(response) }

    context 'when no error occurs' do
      after { controller.send(:with_server_sent_events) }

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
      after { controller.send(:with_server_sent_events) { raise } }

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
