require 'rails_helper'

describe ExercisesController do
  let(:exercise) { FactoryGirl.create(:dummy) }
  let(:user) { FactoryGirl.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    let(:exercise_attributes) { FactoryGirl.build(:dummy).attributes }

    context 'with a valid exercise' do
      let(:request) { proc { post :create, exercise: exercise_attributes } }
      before(:each) { request.call }

      expect_assigns(exercise: Exercise)

      it 'creates the exercise' do
        expect { request.call }.to change(Exercise, :count).by(1)
      end

      expect_redirect
    end

    context 'when including a file' do
      let(:files_attributes) { {'0' => FactoryGirl.build(:file).attributes} }
      let(:request) { proc { post :create, exercise: exercise_attributes.merge(files_attributes: files_attributes) } }

      it 'creates the file' do
        expect { request.call }.to change(CodeOcean::File, :count)
      end
    end

    context 'with a file upload' do
      let(:file_upload) { fixture_file_upload('upload.rb', 'text/x-ruby') }
      let(:files_attributes) { {'0' => FactoryGirl.build(:file).attributes.merge(content: file_upload)} }
      let(:request) { proc { post :create, exercise: exercise_attributes.merge(files_attributes: files_attributes) } }

      it 'creates the file' do
        expect { request.call }.to change(CodeOcean::File, :count)
      end

      it 'assigns the file content' do
        request.call
        file = File.new(Rails.root.join('spec', 'fixtures', 'upload.rb'), 'r')
        expect(Exercise.last.files.first.content).to eq(file.read)
        file.close
      end
    end

    context 'with an invalid exercise' do
      before(:each) { post :create, exercise: {} }

      expect_assigns(exercise: Exercise)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before(:each) { delete :destroy, id: exercise.id }

    expect_assigns(exercise: :exercise)

    it 'destroys the exercise' do
      exercise = FactoryGirl.create(:dummy)
      expect { delete :destroy, id: exercise.id }.to change(Exercise, :count).by(-1)
    end

    expect_redirect(:exercises)
  end

  describe 'GET #edit' do
    before(:each) { get :edit, id: exercise.id }

    expect_assigns(exercise: :exercise)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #implement' do
    let(:request) { proc { get :implement, id: exercise.id } }
    before(:each) { request.call }

    expect_assigns(exercise: :exercise)

    context 'with an existing submission' do
      let!(:submission) { FactoryGirl.create(:submission, exercise_id: exercise.id, user_id: user.id, user_type: InternalUser.class.name) }

      it "populates the editors with the submission's files' content" do
        request.call
        expect(assigns(:files)).to eq(submission.files)
      end
    end

    context 'without an existing submission' do
      it "populates the editors with the exercise's files' content" do
        expect(assigns(:files)).to eq(exercise.files.visible)
      end
    end

    expect_status(200)
    expect_template(:implement)
  end

  describe 'GET #index' do
    let(:scope) { Pundit.policy_scope!(user, Exercise) }
    before(:all) { FactoryGirl.create_pair(:dummy) }
    before(:each) { get :index }

    expect_assigns(exercises: :scope)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before(:each) { get :new }

    expect_assigns(execution_environments: ExecutionEnvironment.all, exercise: Exercise)
    expect_assigns(exercise: Exercise)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    before(:each) { get :show, id: exercise.id }

    expect_assigns(exercise: :exercise)
    expect_status(200)
    expect_template(:show)
  end

  describe 'POST #submit' do
    let(:output) { {} }
    let(:request) { post :submit, format: :json, id: exercise.id, submission: {cause: 'submit', exercise_id: exercise.id} }

    before(:each) do
      expect(controller).to receive(:execute_test_files).and_return([{score: 1, weight: 1}])
      expect(controller).to receive(:score_submission).and_call_original
    end

    context 'when LTI outcomes are supported' do
      before(:each) do
        expect(controller).to receive(:lti_outcome_service?).and_return(true)
      end

      context 'when the score transmission succeeds' do
        before(:each) do
          expect(controller).to receive(:send_score).and_return(status: 'success')
          request
        end

        expect_assigns(exercise: :exercise)

        it 'creates a submission' do
          expect(assigns(:submission)).to be_a(Submission)
        end

        expect_json
        expect_status(200)
      end

      context 'when the score transmission fails' do
        before(:each) do
          expect(controller).to receive(:send_score).and_return(status: 'unsupported')
          request
        end

        expect_assigns(exercise: :exercise)

        it 'creates a submission' do
          expect(assigns(:submission)).to be_a(Submission)
        end

        expect_json
        expect_status(503)
      end
    end

    context 'when LTI outcomes are not supported' do
      before(:each) do
        expect(controller).to receive(:lti_outcome_service?).and_return(false)
        expect(controller).not_to receive(:send_score)
        request
      end

      expect_assigns(exercise: :exercise)

      it 'creates a submission' do
        expect(assigns(:submission)).to be_a(Submission)
      end

      expect_json
      expect_status(200)
    end
  end

  describe 'PUT #update' do
    context 'with a valid exercise' do
      let(:exercise_attributes) { FactoryGirl.build(:dummy).attributes }
      before(:each) { put :update, exercise: exercise_attributes, id: exercise.id }

      expect_assigns(exercise: Exercise)
      expect_redirect
    end

    context 'with an invalid exercise' do
      before(:each) { put :update, exercise: {title: ''}, id: exercise.id }

      expect_assigns(exercise: Exercise)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
