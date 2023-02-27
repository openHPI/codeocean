# frozen_string_literal: true

require 'rails_helper'

describe SubmissionsController do
  render_views

  let(:submission) { create(:submission) }
  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    before do
      controller.request.accept = 'application/json'
    end

    context 'with a valid submission' do
      let(:exercise) { create(:hello_world) }
      let(:perform_request) { proc { post :create, format: :json, params: {submission: attributes_for(:submission, exercise_id: exercise.id)} } }

      before { perform_request.call }

      expect_assigns(submission: Submission)

      it 'creates the submission' do
        expect { perform_request.call }.to change(Submission, :count).by(1)
      end

      expect_json
      expect_http_status(:created)
    end

    context 'with an invalid submission' do
      before { post :create, params: {submission: {}} }

      expect_assigns(submission: Submission)
      expect_json
      expect_http_status(:unprocessable_entity)
    end
  end

  describe 'GET #download_file' do
    context 'with an invalid filename' do
      before { get :download_file, params: {filename: SecureRandom.hex, id: submission.id, format: :json} }

      expect_http_status(:not_found)
    end

    context 'with a valid binary filename' do
      let(:submission) { create(:submission, exercise: create(:sql_select)) }

      before { get :download_file, params: {filename: file.name_with_extension, id: submission.id} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.name == 'exercise' && file.file_type.file_extension == '.sql' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('application/octet-stream')
        expect_http_status(:ok)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end
    end

    context 'with a valid filename' do
      let(:submission) { create(:submission, exercise: create(:audio_video)) }

      before { get :download_file, params: {filename: file.name_with_extension, id: submission.id} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.mp4' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)

        it 'sets the correct redirect' do
          expect(response.location).to eq protected_upload_url(id: file, filename: file.filepath)
        end
      end

      context 'with a non-binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.js' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('application/octet-stream')
        expect_http_status(:ok)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end
    end
  end

  describe 'GET #index' do
    before do
      create_pair(:submission)
      get :index
    end

    expect_assigns(submissions: Submission.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #render_file' do
    let(:file) { submission.files.first }
    let(:signed_url) { AuthenticatedUrlHelper.sign(render_submission_url(submission, filename), submission) }
    let(:token) { Rack::Utils.parse_nested_query(URI.parse(signed_url).query)['token'] }

    context 'with an invalid filename' do
      let(:filename) { SecureRandom.hex }

      before { get :render_file, params: {filename:, id: submission.id, token:} }

      expect_http_status(:not_found)
    end

    context 'with a valid filename' do
      let(:submission) { create(:submission, exercise: create(:audio_video)) }
      let(:filename) { file.name_with_extension }

      before { get :render_file, params: {filename:, id: submission.id, token:} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.mp4' } }
        let(:signed_url_video) { AuthenticatedUrlHelper.sign(render_protected_upload_url(id: file, filename: file.filepath), file) }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)

        it 'sets the correct redirect' do
          expect(response.location).to eq signed_url_video
        end
      end

      context 'with a non-binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.js' } }

        expect_assigns(file: :file)
        expect_assigns(submission: :submission)
        expect_content_type('text/javascript')
        expect_http_status(:ok)

        it 'renders the file content' do
          expect(response.body).to eq(file.content)
        end
      end
    end
  end

  describe 'GET #run' do
    let(:file) { submission.collect_files.detect(&:main_file?) }
    let(:perform_request) { get :run, format: :json, params: {filename: file.filepath, id: submission.id} }

    context 'when no errors occur during execution' do
      before do
        allow_any_instance_of(described_class).to receive(:hijack)
        allow_any_instance_of(Submission).to receive(:run).and_return({})
        allow_any_instance_of(described_class).to receive(:save_testrun_output)
        perform_request
      end

      expect_assigns(submission: :submission)
      expect_assigns(file: :file)
      expect_http_status(204)
    end
  end

  describe 'GET #show' do
    before { get :show, params: {id: submission.id} }

    expect_assigns(submission: :submission)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'GET #show.json' do
    # Render views requested in controller tests in order to get json responses
    # https://github.com/rails/jbuilder/issues/32
    render_views

    before { get :show, params: {id: submission.id}, format: :json }

    expect_assigns(submission: :submission)
    expect_http_status(:ok)

    %i[run test].each do |action|
      describe "##{action}_url" do
        let(:url) { response.parsed_body.with_indifferent_access.fetch("#{action}_url") }

        it "starts like the #{action} path" do
          filename = File.basename(__FILE__)
          expect(url).to start_with(Rails.application.routes.url_helpers.send(:"#{action}_submission_path", submission, filename).sub(filename, ''))
        end

        it 'ends with a placeholder' do
          expect(url).to end_with("#{Submission::FILENAME_URL_PLACEHOLDER}.json")
        end
      end
    end

    describe '#render_url' do
      let(:supported_urls) { response.parsed_body.with_indifferent_access.fetch('render_url') }
      let(:file) { submission.collect_files.detect(&:main_file?) }
      let(:url) { supported_urls.find {|hash| hash[:filepath] == file.filepath }['url'] }

      it 'starts like the render path' do
        expect(url).to start_with(Rails.application.routes.url_helpers.render_submission_url(submission, file.filepath, host: request.host))
      end

      it 'includes a token' do
        expect(url).to include '?token='
      end
    end

    describe '#score_url' do
      let(:url) { response.parsed_body.with_indifferent_access.fetch('score_url') }

      it 'corresponds to the score path' do
        expect(url).to eq(Rails.application.routes.url_helpers.score_submission_path(submission, format: :json))
      end
    end
  end

  describe 'GET #score' do
    let(:perform_request) { proc { get :score, format: :json, params: {id: submission.id} } }

    before do
      allow_any_instance_of(described_class).to receive(:hijack)
      allow_any_instance_of(described_class).to receive(:kill_client_socket)
      perform_request.call
    end

    expect_assigns(submission: :submission)
    expect_http_status(204)
  end

  describe 'GET #test' do
    let(:file) { submission.collect_files.detect(&:teacher_defined_assessment?) }
    let(:output) { {} }

    before do
      file.update(hidden: false)
      allow_any_instance_of(described_class).to receive(:hijack)
      allow_any_instance_of(described_class).to receive(:kill_client_socket)
      get :test, params: {filename: "#{file.filepath}.json", id: submission.id}
    end

    expect_assigns(submission: :submission)
    expect_assigns(file: :file)
    expect_http_status(204)
  end
end
