# frozen_string_literal: true

require 'rails_helper'

describe ExercisesController do
  render_views

  let(:exercise) { create(:dummy) }
  let(:user) { create(:admin) }

  before do
    create(:test_file, context: exercise)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'PUT #batch_update' do
    let(:attributes) { {public: 'true'} }
    let(:perform_request) { proc { put :batch_update, params: {exercises: {0 => attributes.merge(id: exercise.id)}} } }

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
    let(:exercise_attributes) { build(:dummy).attributes }

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
        let(:files_attributes) { {'0' => build(:file).attributes} }

        it 'creates the file' do
          expect { perform_request.call }.to change(CodeOcean::File, :count)
        end
      end

      context 'when uploading a file' do
        let(:files_attributes) { {'0' => build(:file, file_type:).attributes.merge(content: uploaded_file)} }

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
        let!(:submission) { create(:submission, exercise_id: exercise.id, user_id: user.id, user_type: user.class.name) }

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
      let(:user) { create(:teacher) }

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
      2.times { create(:submission, cause: 'autosave', user: external_user, exercise:) }
      2.times { create(:submission, cause: 'run', user: external_user, exercise:) }
      create(:submission, cause: 'assess', user: external_user, exercise:)
    end

    context 'when viewing the default submission statistics page without a parameter' do
      it 'does not list autosaved submissions' do
        perform_request
        expect(assigns(:all_events).filter {|event| event.is_a? Submission }).to contain_exactly(
          an_object_having_attributes(cause: 'run', user_id: external_user.id),
          an_object_having_attributes(cause: 'assess', user_id: external_user.id),
          an_object_having_attributes(cause: 'run', user_id: external_user.id)
        )
      end
    end

    context 'when including autosaved submissions via the query parameter' do
      let(:params) { super().merge(show_autosaves: 'true') }

      it 'lists all submissions, including autosaved submissions' do
        perform_request
        submissions = assigns(:all_events).filter {|event| event.is_a? Submission }
        expect(submissions).to match_array Submission.all
        expect(submissions).to include an_object_having_attributes(cause: 'autosave', user_id: external_user.id)
      end
    end
  end

  describe 'POST #submit' do
    let(:output) { {} }
    let(:perform_request) { post :submit, format: :json, params: {id: exercise.id, submission: {cause: 'submit', exercise_id: exercise.id}} }
    let(:user) { create(:external_user) }
    let(:scoring_response) do
      [{
        status: :ok,
        stdout: '',
        stderr: '',
        waiting_for_container_time: 0,
        container_execution_time: 0,
        file_role: 'teacher_defined_test',
        count: 1,
        failed: 0,
        error_messages: [],
        passed: 1,
        score: 1.0,
        filename: 'index.html_spec.rb',
        message: 'Well done.',
        weight: 2.0,
      }]
    end

    before do
      create(:lti_parameter, external_user: user, exercise:)
      submission = build(:submission, exercise:, user:)
      allow(submission).to receive(:normalized_score).and_return(1)
      allow(submission).to receive(:calculate_score).and_return(scoring_response)
      allow(Submission).to receive(:create).and_return(submission)
    end

    context 'when LTI outcomes are supported' do
      before do
        allow(controller).to receive(:lti_outcome_service?).and_return(true)
      end

      context 'when the score transmission succeeds' do
        before do
          allow(controller).to receive(:send_score).and_return(status: 'success')
          perform_request
        end

        expect_assigns(exercise: :exercise)

        it 'creates a submission' do
          expect(assigns(:submission)).to be_a(Submission)
        end

        expect_json
        expect_http_status(:ok)
      end

      context 'when the score transmission fails' do
        before do
          allow(controller).to receive(:send_score).and_return(status: 'unsupported')
          perform_request
        end

        expect_assigns(exercise: :exercise)

        it 'creates a submission' do
          expect(assigns(:submission)).to be_a(Submission)
        end

        expect_json
        expect_http_status(:service_unavailable)
      end
    end

    context 'when LTI outcomes are not supported' do
      before do
        allow(controller).to receive(:lti_outcome_service?).and_return(false)
        perform_request
      end

      expect_assigns(exercise: :exercise)

      it 'creates a submission' do
        expect(assigns(:submission)).to be_a(Submission)
      end

      it 'does not send scores' do
        expect(controller).not_to receive(:send_score)
      end

      expect_json
      expect_http_status(:ok)
    end
  end

  describe 'PUT #update' do
    context 'with a valid exercise' do
      let(:exercise_attributes) { build(:dummy).attributes }

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

    before { allow(ExerciseService::CheckExternal).to receive(:call).with(uuid: exercise.uuid, codeharbor_link:).and_return(external_check_hash) }

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
      let(:codeharbor_link) { create(:codeharbor_link, api_key: 'anotherkey') }

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
      before { allow(ProformaService::Import).to receive(:call).and_raise(Proforma::PreImportValidationError) }

      it 'responds with correct status code' do
        post_request
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when import fails with ExerciseNotOwned' do
      before { allow(ProformaService::Import).to receive(:call).and_raise(Proforma::ExerciseNotOwned) }

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
end
