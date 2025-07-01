# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExercisesController do
  render_views

  let(:exercise) { create(:dummy) }
  let(:user) { create(:admin) }

  before do
    create(:test_file, context: exercise)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'PUT #batch_update' do
    let(:attributes) { {public: 'true'} }
    let(:params) { ActionController::Parameters.new(public: 'true').permit! }
    let(:perform_request) { proc { put :batch_update, params: {exercises: {0 => params.merge(id: exercise.id)}} } }

    before { perform_request.call }

    it 'updates the exercises' do
      expect_any_instance_of(Exercise).to receive(:update).with(attributes)
      perform_request.call
    end

    expect_json
    expect_http_status(:ok)
  end

  describe 'POST #clone' do
    let(:perform_request) { proc { post :clone, params: {id: exercise.id} } }

    context 'when saving succeeds' do
      before { perform_request.call }

      expect_assigns(exercise: Exercise)

      it 'clones the exercise' do
        expect_any_instance_of(Exercise).to receive(:duplicate).with(hash_including(public: false, user:)).and_call_original
        expect { perform_request.call }.to change(Exercise, :count).by(1)
      end

      it 'generates a new token' do
        expect(Exercise.last.token).not_to eq(exercise.token)
      end

      expect_redirect(Exercise.last)
    end

    context 'when exercise has uuid' do
      let(:exercise) { create(:dummy, uuid: SecureRandom.hex) }

      it 'clones the exercise' do
        expect_any_instance_of(Exercise).to receive(:duplicate).with(hash_including(public: false, user:)).and_call_original
        expect { perform_request.call }.to change(Exercise, :count).by(1)
      end
    end

    context 'when saving fails' do
      before do
        allow_any_instance_of(Exercise).to receive(:save).and_return(false)
        perform_request.call
      end

      expect_assigns(exercise: Exercise)
      expect_flash_message(:danger, :'shared.message_failure')
      expect_redirect(:exercise)
    end
  end

  describe 'POST #create' do
    let(:exercise_attributes) { build(:dummy).attributes.except('created_at', 'id', 'token', 'updated_at', 'user_id', 'user_type', 'uuid') }

    context 'with a valid exercise' do
      let(:perform_request) { proc { post :create, params: {exercise: exercise_attributes} } }

      before { perform_request.call }

      expect_assigns(exercise: Exercise)

      it 'creates the exercise' do
        expect { perform_request.call }.to change(Exercise, :count).by(1)
      end

      expect_redirect(Exercise.last)
    end

    context 'when including a file' do
      let(:perform_request) { proc { post :create, params: {exercise: exercise_attributes.merge(files_attributes:)} } }

      context 'when specifying the file content within the form' do
        let(:files_attributes) { {'0' => build(:file).attributes.except('context_id', 'context_type', 'created_at', 'hashed_content', 'updated_at')} }

        it 'creates the file' do
          expect { perform_request.call }.to change(CodeOcean::File, :count)
        end
      end

      context 'when uploading a file' do
        let(:files_attributes) { {'0' => build(:file, file_type:).attributes.except('context_id', 'context_type', 'created_at', 'hashed_content', 'updated_at').merge(content: uploaded_file)} }

        context 'when uploading a binary file' do
          let(:file_path) { Rails.root.join('db/seeds/audio_video/devstories.mp4') }
          let(:file_type) { create(:dot_mp4) }
          let(:uploaded_file) { Rack::Test::UploadedFile.new(file_path, 'video/mp4', true) }

          it 'creates the file' do
            expect { perform_request.call }.to change(CodeOcean::File, :count)
          end

          it 'assigns the native file' do
            perform_request.call
            expect(Exercise.last.files.first.native_file).to be_a(FileUploader)
          end
        end

        context 'when uploading a non-binary file' do
          let(:file_path) { Rails.root.join('db/seeds/fibonacci/exercise.rb') }
          let(:file_type) { create(:dot_rb) }
          let(:uploaded_file) { Rack::Test::UploadedFile.new(file_path, 'text/x-ruby', false) }

          it 'creates the file' do
            expect { perform_request.call }.to change(CodeOcean::File, :count)
          end

          it 'assigns the file content' do
            perform_request.call
            expect(Exercise.last.files.first.content).to eq(File.read(file_path))
          end
        end
      end
    end

    context 'with an invalid exercise' do
      before { post :create, params: {exercise: {}} }

      expect_assigns(exercise: Exercise)
      expect_http_status(:ok)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: exercise.id} }

    expect_assigns(exercise: :exercise)

    it 'destroys the exercise' do
      exercise = create(:dummy)
      expect { delete :destroy, params: {id: exercise.id} }.to change(Exercise, :count).by(-1)
    end

    expect_redirect(:exercises)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: exercise.id} }

    expect_assigns(exercise: :exercise)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'GET #implement' do
    let(:perform_request) { proc { get :implement, params: {id: exercise.id} } }

    context 'with an exercise with visible files' do
      let(:exercise) { create(:fibonacci) }

      before { perform_request.call }

      expect_assigns(exercise: :exercise)

      context 'with an existing submission' do
        let!(:submission) { create(:submission, exercise:, contributor: user) }

        it "populates the editors with the submission's files' content" do
          perform_request.call
          expect(assigns(:files)).to eq(submission.files)
        end
      end

      context 'without an existing submission' do
        it "populates the editors with the exercise's files' content" do
          expect(assigns(:files)).to eq(exercise.files.visible)
        end
      end

      expect_http_status(:ok)
      expect_template(:implement)
    end

    context 'with an exercise without visible files' do
      before { perform_request.call }

      expect_assigns(exercise: :exercise)
      expect_flash_message(:alert, :'exercises.implement.no_files')
      expect_redirect(:exercise)
    end

    context 'with other users accessing an unpublished exercise' do
      let(:exercise) { create(:fibonacci, unpublished: true) }
      let(:user) { create(:external_teacher) }

      before { perform_request.call }

      expect_assigns(exercise: :exercise)
      expect_flash_message(:alert, :'exercises.implement.unpublished')
      expect_redirect(:exercise)
    end
  end

  describe 'GET #index' do
    let(:scope) { Pundit.policy_scope!(user, Exercise) }

    before do
      create_pair(:dummy)
      get :index
    end

    expect_assigns(exercises: :scope)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before { get :new }

    expect_assigns(execution_environments: ExecutionEnvironment.all, exercise: Exercise)
    expect_assigns(exercise: Exercise)
    expect_http_status(:ok)
    expect_template(:new)
  end

  describe 'GET #show' do
    context 'when being admin' do
      before { get :show, params: {id: exercise.id} }

      expect_assigns(exercise: :exercise)
      expect_http_status(:ok)
      expect_template(:show)
    end
  end

  describe 'GET #reload' do
    context 'when being anyone' do
      let(:exercise) { create(:fibonacci) }

      before { get :reload, format: :json, params: {id: exercise.id} }

      expect_assigns(exercise: :exercise)
      expect_http_status(:ok)
      expect_template(:reload)
    end
  end

  describe 'GET #statistics' do
    before { get :statistics, params: {id: exercise.id} }

    expect_assigns(exercise: :exercise)
    expect_http_status(:ok)
    expect_template(:statistics)
  end

  describe 'GET #external_user_statistics' do
    let(:perform_request) { get :external_user_statistics, params: }
    let(:params) { {id: exercise.id, external_user_id: external_user.id} }
    let(:external_user) { create(:external_user) }

    before do
      create_list(:submission, 2, cause: 'autosave', contributor: external_user, exercise:)
      create_list(:submission, 2, cause: 'run', contributor: external_user, exercise:)
      create(:submission, cause: 'assess', contributor: external_user, exercise:)
    end

    context 'when viewing the default submission statistics page without a parameter' do
      it 'does not list autosaved submissions' do
        perform_request
        expect(assigns(:all_events).filter {|event| event.is_a? Submission }).to contain_exactly(
          an_object_having_attributes(cause: 'run', contributor: external_user),
          an_object_having_attributes(cause: 'assess', contributor: external_user),
          an_object_having_attributes(cause: 'run', contributor: external_user)
        )
      end
    end

    context 'when including autosaved submissions via the query parameter' do
      let(:params) { super().merge(show_autosaves: 'true') }

      it 'lists all submissions, including autosaved submissions' do
        perform_request
        submissions = assigns(:all_events).filter {|event| event.is_a? Submission }
        expect(submissions).to match_array Submission.all
        expect(submissions).to include an_object_having_attributes(cause: 'autosave', contributor: external_user)
      end
    end
  end

  describe 'PUT #update' do
    context 'with a valid exercise' do
      let(:exercise_attributes) { build(:dummy).attributes.except('created_at', 'id', 'token', 'updated_at', 'uuid', 'user_id', 'user_type') }

      before { put :update, params: {exercise: exercise_attributes, id: exercise.id} }

      expect_assigns(exercise: Exercise)
      expect_redirect(:exercise)
    end

    context 'with an invalid exercise' do
      before { put :update, params: {exercise: {title: ''}, id: exercise.id} }

      expect_assigns(exercise: Exercise)
      expect_http_status(:ok)
      expect_template(:edit)
    end
  end

  RSpec::Matchers.define_negated_matcher :not_include, :include
  # RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 99999

  describe 'POST #export_external_check' do
    render_views

    let(:post_request) { post :export_external_check, params: {id: exercise.id} }
    let!(:codeharbor_link) { create(:codeharbor_link, user:) }
    let(:external_check_hash) { {message:, uuid_found: true, update_right:, error:} }
    let(:message) { 'message' }
    let(:update_right) { true }
    let(:error) { nil }

    before do
      allow(ExerciseService::CheckExternal).to receive(:call).with(uuid: exercise.uuid, codeharbor_link:).and_return(external_check_hash)
      stub_const('CodeharborLinkPolicy::CODEHARBOR_CONFIG', {enabled: true})
    end

    it 'renders the correct contents as json' do
      post_request
      expect(response.parsed_body.symbolize_keys[:message]).to eq('message')
      expect(response.parsed_body.symbolize_keys[:actions]).to(
        include('button').and(include('Abort').and(include('Export')))
      )
      expect(response.parsed_body.symbolize_keys[:actions]).to(
        not_include('Retry').and(not_include('Hide'))
      )
    end

    context 'when there is an error' do
      let(:error) { 'error' }

      it 'renders the correct contents as json' do
        post_request
        expect(response.parsed_body.symbolize_keys[:message]).to eq('message')
        expect(response.parsed_body.symbolize_keys[:actions]).to(
          include('button').and(include('Abort')).and(include('Retry'))
        )
        expect(response.parsed_body.symbolize_keys[:actions]).to(
          not_include('Export').and(not_include('Hide'))
        )
      end
    end

    context 'when update_right is false' do
      let(:update_right) { false }

      it 'renders the correct contents as json' do
        post_request
        expect(response.parsed_body.symbolize_keys[:message]).to eq('message')
        expect(response.parsed_body.symbolize_keys[:actions]).to(
          include('button').and(include('Abort'))
        )
        expect(response.parsed_body.symbolize_keys[:actions]).to(
          not_include('Retry').and(not_include('Export')).and(not_include('Hide'))
        )
      end
    end
  end

  describe 'POST #export_external_confirm' do
    render_views

    let!(:codeharbor_link) { create(:codeharbor_link, user:) }
    let(:post_request) { post :export_external_confirm, params: {id: exercise.id, codeharbor_link: codeharbor_link.id} }
    let(:error) { nil }
    let(:zip) { 'zip' }

    before do
      allow(ProformaService::ExportTask).to receive(:call).with(exercise:).and_return(zip)
      allow(ExerciseService::PushExternal).to receive(:call).with(zip:, codeharbor_link:).and_return(error)
      stub_const('CodeharborLinkPolicy::CODEHARBOR_CONFIG', {enabled: true})
    end

    it 'renders correct response' do
      post_request

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.symbolize_keys[:message]).to(include('successfully exported'))
      expect(response.parsed_body.symbolize_keys[:status]).to(eql('success'))
      expect(response.parsed_body.symbolize_keys[:actions]).to(include('button').and(include('Close')))
      expect(response.parsed_body.symbolize_keys[:actions]).to(not_include('Retry').and(not_include('Abort')))
    end

    context 'when an error occurs' do
      let(:error) { 'exampleerror' }

      it 'renders correct response' do
        post_request
        expect(response).to have_http_status(:success)
        expect(response.parsed_body.symbolize_keys[:message]).to(include('failed').and(include('exampleerror')))
        expect(response.parsed_body.symbolize_keys[:status]).to(eql('fail'))
        expect(response.parsed_body.symbolize_keys[:actions]).to(include('button').and(include('Retry')).and(include('Close')))
        expect(response.parsed_body.symbolize_keys[:actions]).to(not_include('Abort'))
      end
    end
  end

  describe 'POST #import_uuid_check' do
    let(:exercise) { create(:dummy, uuid: SecureRandom.uuid) }
    let!(:codeharbor_link) { create(:codeharbor_link, user:) }
    let(:uuid) { exercise.reload.uuid }
    let(:post_request) { post :import_uuid_check, params: {uuid:} }
    let(:headers) { {'Authorization' => "Bearer #{codeharbor_link.api_key}"} }

    before { request.headers.merge! headers }

    it 'renders correct response' do
      post_request
      expect(response).to have_http_status(:success)

      expect(response.parsed_body.symbolize_keys[:uuid_found]).to be true
      expect(response.parsed_body.symbolize_keys[:update_right]).to be true
    end

    context 'when api_key is incorrect' do
      let(:headers) { {'Authorization' => 'Bearer XXXXXX'} }

      it 'renders correct response' do
        post_request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user cannot update the exercise' do
      let(:user) { create(:external_teacher) }
      let(:codeharbor_link) { create(:codeharbor_link, user:, api_key: 'anotherkey') }

      it 'renders correct response' do
        post_request
        expect(response).to have_http_status(:success)

        expect(response.parsed_body.symbolize_keys[:uuid_found]).to be true
        expect(response.parsed_body.symbolize_keys[:update_right]).to be false
      end
    end

    context 'when the searched exercise does not exist' do
      let(:uuid) { 'anotheruuid' }

      it 'renders correct response' do
        post_request
        expect(response).to have_http_status(:success)

        expect(response.parsed_body.symbolize_keys[:uuid_found]).to be false
      end
    end

    context 'when uuid is nil' do
      let(:exercise) { create(:dummy, uuid: nil) }
      let(:uuid) { nil }

      it 'renders correct response' do
        post_request
        expect(response).to have_http_status(:success)

        expect(response.parsed_body.symbolize_keys[:uuid_found]).to be false
      end
    end
  end

  describe 'POST #import_task' do
    let(:codeharbor_link) { create(:codeharbor_link, user:) }
    let!(:imported_exercise) { create(:fibonacci) }
    let(:post_request) { post :import_task, body: zip_file_content }
    let(:zip_file_content) { 'zipped task xml' }
    let(:headers) { {'Authorization' => "Bearer #{codeharbor_link.api_key}"} }

    before do
      request.headers.merge! headers
      allow(ProformaService::Import).to receive(:call).and_return(imported_exercise)
    end

    it 'responds with correct status code' do
      post_request
      expect(response).to have_http_status(:created)
    end

    it 'calls service' do
      post_request
      expect(ProformaService::Import).to have_received(:call).with(zip: be_a(Tempfile).and(has_content(zip_file_content)), user:)
    end

    context 'when import fails with ProformaError' do
      before { allow(ProformaService::Import).to receive(:call).and_raise(ProformaXML::PreImportValidationError) }

      it 'responds with correct status code' do
        post_request
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when import fails with ExerciseNotOwned' do
      before { allow(ProformaService::Import).to receive(:call).and_raise(ProformaXML::ExerciseNotOwned) }

      it 'responds with correct status code' do
        post_request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when import fails due to another error' do
      before { allow(ProformaService::Import).to receive(:call).and_raise(StandardError) }

      it 'responds with correct status code' do
        post_request
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'when the imported exercise is invalid' do
      before { allow(ProformaService::Import).to receive(:call) { imported_exercise.tap {|e| e.files = [] }.tap {|e| e.title = nil } } }

      it 'responds with correct status code' do
        expect { post_request }.not_to(change { imported_exercise.reload.files.count })
      end
    end
  end

  describe 'GET #download_proforma' do
    subject(:get_request) { get :download_proforma, params: {id: exercise.id} }

    let(:zip) { instance_double(StringIO, string: 'dummy') }

    context 'when export is successful' do
      before do
        allow(ProformaService::ExportTask).to receive(:call).with(exercise:).and_return(zip)
      end

      it 'calls the ExportTask service' do
        get_request
        expect(ProformaService::ExportTask).to have_received(:call)
      end

      it 'sends the correct data' do
        get_request
        expect(response.body).to eql 'dummy'
      end

      it 'sets the correct Content-Type header' do
        get_request
        expect(response.header['Content-Type']).to eql 'application/zip'
      end

      it 'sets the correct Content-Disposition header' do
        get_request
        expect(response.header['Content-Disposition']).to include "attachment; filename=\"exercise_#{exercise.id}.zip\""
      end
    end

    context 'when export fails with PostGenerateValidationError' do
      let(:error_message) { '["Error 1", "Error 2"]' }

      before do
        allow(ProformaService::ExportTask).to receive(:call).with(exercise:).and_raise(ProformaXML::PostGenerateValidationError.new(error_message))
      end

      it 'redirects to root' do
        get_request
        expect(response).to redirect_to(:root)
      end

      it 'sets a danger flash message' do
        get_request
        expect(flash[:danger]).to eq('Error 1<br>Error 2')
      end
    end
  end

  describe 'POST #import_start' do
    let(:valid_file) { fixture_file_upload('proforma_import/testfile.zip', 'application/zip') }
    let(:invalid_file) { 'invalid_file' }
    let(:mock_uploader) { instance_double(ProformaZipUploader) }
    let(:uuid) { 'mocked-uuid' }
    let(:post_request) { post :import_start, params: {file: file} }
    let(:file) { valid_file }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(ProformaZipUploader).to receive(:new).and_return(mock_uploader)
    end

    context 'when the file is valid' do
      before do
        allow(ProformaService::UuidFromZip).to receive(:call).and_return(uuid)
        allow(mock_uploader).to receive(:cache!)
        allow(mock_uploader).to receive(:cache_name).and_return('mocked-cache-name')
      end

      context 'when the exercise exists and is updatable' do
        before do
          allow(controller).to receive(:uuid_check).with(user: user, uuid: uuid)
            .and_return(uuid_found: true, update_right: true)
        end

        it 'renders success JSON with updatable message' do
          post_request

          expect(response).to have_http_status(:ok)
          parsed_response = response.parsed_body
          expect(parsed_response['status']).to eq('success')
          expect(parsed_response['message']).to eq(I18n.t('exercises.import_start.exercise_exists_and_is_updatable'))
        end
      end

      context 'when the exercise exists but is not updatable' do
        before do
          allow(controller).to receive(:uuid_check).with(user: user, uuid: uuid)
            .and_return(uuid_found: true, update_right: false)
        end

        it 'renders success JSON with not updatable message' do
          post_request

          expect(response).to have_http_status(:ok)
          parsed_response = response.parsed_body
          expect(parsed_response['status']).to eq('success')
          expect(parsed_response['message']).to eq(I18n.t('exercises.import_start.exercise_exists_and_is_not_updatable'))
        end
      end

      context 'when the exercise does not exist' do
        before do
          allow(controller).to receive(:uuid_check).with(user: user, uuid: uuid)
            .and_return(uuid_found: false, update_right: false)
        end

        it 'renders success JSON with importable message' do
          post_request

          expect(response).to have_http_status(:ok)
          parsed_response = response.parsed_body
          expect(parsed_response['status']).to eq('success')
          expect(parsed_response['message']).to eq(I18n.t('exercises.import_start.exercise_is_importable'))
        end
      end
    end

    context 'when the file is invalid' do
      let(:file) { invalid_file }

      it 'renders failure JSON with correct error' do
        post_request

        expect(response).to have_http_status(:ok)
        parsed_response = response.parsed_body
        expect(parsed_response['status']).to eq('failure')
        expect(parsed_response['message']).to eq(I18n.t('exercises.import_start.choose_file_error'))
      end
    end

    context 'when the uploaded zip file is invalid' do
      it 'renders failure JSON with correct error' do
        error_message = I18n.t('exercises.import_proforma.import_errors.invalid_zip')
        allow(ProformaService::UuidFromZip).to receive(:call).and_raise(ProformaXML::InvalidZip.new(error_message))

        post_request
        expect(response).to have_http_status(:ok)

        parsed_response = response.parsed_body
        expect(parsed_response['status']).to eq('failure')
        expect(parsed_response['message']).to include(error_message)
      end
    end
  end

  describe 'POST #import_confirm' do
    let(:file_id) { 'file_id' }
    let(:mock_uploader) { instance_double(ProformaZipUploader, file: 'mocked_file') }
    let(:post_request) { post :import_confirm, params: {file_id: file_id} }

    before do
      allow(ProformaZipUploader).to receive(:new).and_return(mock_uploader)
    end

    context 'when the import is successful' do
      before do
        allow(mock_uploader).to receive(:retrieve_from_cache!).with(file_id)
        allow(ProformaService::Import).to receive(:call).with(zip: 'mocked_file', user: user).and_return(exercise)
        allow(exercise).to receive(:save!).and_return(true)
      end

      it 'renders success JSON' do
        post_request

        expect(response).to have_http_status(:ok)
        parsed_response = response.parsed_body
        expect(parsed_response['status']).to eq('success')
        expect(parsed_response['message']).to eq(I18n.t('exercises.import_confirm.success'))
      end
    end

    context 'when ProformaError or validation error occurs' do
      before do
        allow(mock_uploader).to receive(:retrieve_from_cache!).with(file_id)
        allow(ProformaService::Import).to receive(:call).and_raise(ProformaXML::ProformaError, 'Proforma error')
      end

      it 'renders failure JSON' do
        post_request

        expect(response).to have_http_status(:ok)
        parsed_response = response.parsed_body
        expect(parsed_response['status']).to eq('failure')
        expect(parsed_response['message']).to eq(I18n.t('exercises.import_confirm.error', error: 'Proforma error message'))
      end
    end

    context 'when StandardError occurs' do
      before do
        allow(mock_uploader).to receive(:retrieve_from_cache!).and_raise(StandardError, 'Unexpected error')
        allow(Sentry).to receive(:capture_exception)
      end

      it 'logs the error and renders internal error JSON' do
        post_request

        expect(Sentry).to have_received(:capture_exception).with(instance_of(StandardError))
        expect(response).to have_http_status(:ok)
        parsed_response = response.parsed_body
        expect(parsed_response['status']).to eq('failure')
        expect(parsed_response['message']).to eq(I18n.t('exercises.import_proforma.import_errors.internal_error'))
      end
    end
  end
end
