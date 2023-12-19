# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionsController do
  render_views

  let(:exercise) { create(:math) }
  let(:cause) { 'save' }
  let(:submission) { create(:submission, exercise:, contributor:, cause:) }

  shared_examples 'a regular user' do |record_not_found_status_code|
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

    describe 'GET #download' do
      let(:perform_request) { proc { get :download, params: {id: submission.id} } }

      before { perform_request.call }

      expect_assigns(submission: :submission)
      expect_http_status(:ok)
    end

    describe 'GET #download_file' do
      context 'with an invalid filename' do
        before { get :download_file, params: {filename: SecureRandom.hex, id: submission.id, format: :json} }

        expect_http_status(record_not_found_status_code)
      end

      context 'with a valid binary filename' do
        let(:exercise) { create(:sql_select) }
        let(:submission) { create(:submission, exercise:, contributor:) }

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
        let(:exercise) { create(:audio_video) }
        let(:submission) { create(:submission, exercise:, contributor:) }

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

    describe 'GET #finalize' do
      let(:perform_request) { proc { get :finalize, params: {id: submission.id} } }
      let(:cause) { 'assess' }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(submission: :submission)
        expect_redirect
      end

      it 'updates cause to submit' do
        expect { perform_request.call && submission.reload }.to change(submission, :cause).from('assess').to('submit')
      end

      context 'when contributing to a community solution is possible' do
        let!(:community_solution) { CommunitySolution.create(exercise:) }

        before do
          allow(Java21Study).to receive(:allow_redirect_to_community_solution?).and_return(true)
          perform_request.call
        end

        expect_redirect { edit_community_solution_path(community_solution, lock_id: CommunitySolutionLock.last) }
      end

      context 'when sharing exercise feedback is desired' do
        before do
          uef&.save!
          allow_any_instance_of(Submission).to receive(:redirect_to_feedback?).and_return(true)
          perform_request.call
        end

        context 'without any previous feedback' do
          let(:uef) { nil }

          expect_redirect { new_exercise_user_exercise_feedback_path(exercise_id: submission.exercise) }
        end

        context 'with a previous feedback for the same exercise' do
          let(:uef) { create(:user_exercise_feedback, exercise:, user: current_user) }

          expect_redirect { edit_exercise_user_exercise_feedback_path(uef, exercise_id: exercise) }
        end
      end

      context 'with an RfC' do
        before do
          rfc.save!
          allow_any_instance_of(Submission).to receive(:redirect_to_feedback?).and_return(false)
          perform_request.call
        end

        context 'when an own RfC is unsolved' do
          let(:rfc) { create(:rfc, user: current_user, exercise:, submission:) }

          expect_flash_message(:notice, I18n.t('exercises.editor.exercise_finished_redirect_to_own_rfc'))
          expect_redirect { request_for_comment_url(rfc) }
        end

        context 'when another RfC is unsolved' do
          let(:rfc) { create(:rfc, exercise:) }

          expect_flash_message(:notice, I18n.t('exercises.editor.exercise_finished_redirect_to_rfc'))
          expect_redirect { request_for_comment_url(rfc) }
        end
      end

      context 'when neither a community solution, feedback nor RfC is available' do
        before do
          allow_any_instance_of(Submission).to receive(:redirect_to_feedback?).and_return(false)
          perform_request.call
        end

        expect_redirect { lti_return_path(submission_id: submission.id) }
      end
    end

    describe 'GET #render_file' do
      let(:file) { submission.files.first }
      let(:signed_url) { AuthenticatedUrlHelper.sign(render_submission_url(submission, filename), submission) }
      let(:token) { Rack::Utils.parse_nested_query(URI.parse(signed_url).query)['token'] }

      context 'with an invalid filename' do
        let(:filename) { SecureRandom.hex }

        before { get :render_file, params: {filename:, id: submission.id, token:} }

        expect_http_status(record_not_found_status_code)
      end

      context 'with a valid filename' do
        let(:exercise) { create(:audio_video) }
        let(:submission) { create(:submission, exercise:, contributor:) }
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
          allow_any_instance_of(described_class).to receive(:close_client_connection)
          allow_any_instance_of(Submission).to receive(:run).and_return({})
          allow_any_instance_of(described_class).to receive(:save_testrun_output)
          perform_request
        end

        expect_assigns(submission: :submission)
        expect_assigns(file: :file)
        expect_http_status(204)
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

    describe 'GET #show' do
      before { get :show, params: {id: submission.id} }

      expect_assigns(submission: :submission)
      expect_http_status(:ok)
      expect_template(:show)
    end

    describe 'GET #show.json' do
      before { get :show, params: {id: submission.id}, format: :json }

      expect_assigns(submission: :submission)
      expect_http_status(:ok)

      it 'includes the desired fields' do
        expect(response.parsed_body.keys).to include('id', 'files')
        expect(response.parsed_body['files'].first.keys).to include('id', 'file_id')
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

  shared_examples 'denies access for regular, non-admin users' do # rubocop:disable RSpec/SharedContext
    describe 'GET #index' do
      before do
        create_pair(:submission, contributor:, exercise:)
        get :index
      end

      expect_redirect(:root)
    end
  end

  context 'with an admin user' do
    let(:contributor) { create(:admin) }
    let(:current_user) { contributor }

    before { allow(controller).to receive_messages(current_user:) }

    describe 'GET #index' do
      before do
        create_pair(:submission, contributor:, exercise:)
        get :index
      end

      expect_assigns(submissions: Submission.all)
      expect_http_status(:ok)
      expect_template(:index)
    end

    it_behaves_like 'a regular user', :not_found
  end

  context 'with a programming group' do
    let(:group_author) { create(:external_user) }
    let(:other_group_author) { create(:external_user) }
    let(:contributor) { create(:programming_group, exercise:, users: [group_author, other_group_author]) }
    let(:current_user) { group_author }

    before { allow(controller).to receive_messages(current_contributor: contributor, current_user:) }

    it_behaves_like 'a regular user', :unauthorized
    it_behaves_like 'denies access for regular, non-admin users'
  end

  context 'with a learner' do
    let(:contributor) { create(:external_user) }
    let(:current_user) { contributor }

    before { allow(controller).to receive_messages(current_user:) }

    it_behaves_like 'a regular user', :unauthorized
    it_behaves_like 'denies access for regular, non-admin users'
  end
end
