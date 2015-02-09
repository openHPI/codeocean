require 'rails_helper'

describe SubmissionsController do
  let(:submission) { FactoryGirl.create(:submission) }
  let(:user) { FactoryGirl.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    before(:each) do
      controller.request.accept = 'application/json'
    end

    context 'with a valid submission' do
      let(:exercise) { FactoryGirl.create(:hello_world) }
      let(:request) { Proc.new { post :create, format: :json, submission: FactoryGirl.attributes_for(:submission, exercise_id: exercise.id) } }
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
      let(:file) { submission.files.first }
      before(:each) { get :download_file, filename: file.name_with_extension, id: submission.id }

      expect_assigns(file: :file)
      expect_assigns(submission: :submission)
      expect_content_type('application/octet-stream')
      expect_status(200)

      it 'sets the correct filename' do
        expect(response.headers['Content-Disposition']).to eq("attachment; filename=\"#{file.name_with_extension}\"")
      end
    end
  end

  describe 'GET #index' do
    before(:all) { FactoryGirl.create_pair(:submission) }
    before(:each) { get :index }

    expect_assigns(submissions: Submission.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #render_file' do
    context 'with an invalid filename' do
      before(:each) { get :render_file, filename: SecureRandom.hex, id: submission.id }

      expect_status(404)
    end

    context 'with a valid filename' do
      let(:file) { submission.files.first }
      let(:file_type) { FactoryGirl.create(:dot_xml) }
      let(:request) { Proc.new { get :render_file, filename: file.name_with_extension, id: submission.id } }

      before(:each) do
        file.update(file_type: file_type)
        request.call
      end

      expect_assigns(file: :file)
      expect_assigns(submission: :submission)
      expect_status(200)

      it 'renders the file content' do
        expect(response.body).to eq(file.content)
      end

      it 'sets the correct MIME type' do
        mime_type = Mime::Type.lookup_by_extension(file_type.file_extension.gsub(/^\./, ''))
        expect(Mime::Type).to receive(:lookup_by_extension).at_least(:once).and_return(mime_type)
        request.call
      end
    end
  end

  describe 'GET #run' do
    let(:filename) { submission.collect_files.detect(&:main_file?).name_with_extension }

    before(:each) do
      expect_any_instance_of(ActionController::Live::SSE).to receive(:write).at_least(3).times
    end

    context 'when no errors occur during execution' do
      before(:each) do
        expect_any_instance_of(DockerClient).to receive(:execute_run_command).with(submission, filename).and_return({})
        get :run, filename: filename, id: submission.id
      end

      expect_assigns(docker_client: DockerClient)
      expect_assigns(server_sent_event: ActionController::Live::SSE)
      expect_assigns(submission: :submission)
      expect_content_type('text/event-stream')
      expect_status(200)
    end

    context 'when an error occurs during execution' do
      let(:hint) { "Your object 'main' of class 'Object' does not understand the method 'foo'." }
      let(:stderr) { "undefined method `foo' for main:Object (NoMethodError)" }

      before(:each) do
        expect_any_instance_of(DockerClient).to receive(:execute_run_command).with(submission, filename).and_yield(:stderr, stderr)
      end

      after(:each) { get :run, filename: filename, id: submission.id }

      context 'when the error is covered by a hint' do
        before(:each) do
          expect_any_instance_of(Whistleblower).to receive(:generate_hint).with(stderr).and_return(hint)
        end

        it 'does not store the error' do
          expect(Error).not_to receive(:create)
        end
      end

      context 'when the error is not covered by a hint' do
        before(:each) do
          expect_any_instance_of(Whistleblower).to receive(:generate_hint).with(stderr)
        end

        it 'stores the error' do
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

  describe 'GET #test' do
    let(:filename) { submission.collect_files.detect(&:teacher_defined_test?).name_with_extension }
    let(:output) { {} }

    before(:each) do
      expect_any_instance_of(DockerClient).to receive(:execute_test_command).with(submission, filename)
      get :test, filename: filename, id: submission.id
    end

    expect_assigns(docker_client: DockerClient)
    expect_assigns(submission: :submission)
    expect_json
    expect_status(200)
  end
end
