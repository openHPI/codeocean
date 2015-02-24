require 'rails_helper'

describe CodeOcean::FilesController do
  let(:user) { FactoryGirl.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    let(:submission) { FactoryGirl.create(:submission, user: user) }

    context 'with a valid file' do
      let(:request) { proc { post :create, code_ocean_file: FactoryGirl.build(:file, context: submission).attributes, format: :json } }
      before(:each) { request.call }

      expect_assigns(file: CodeOcean::File)

      it 'creates the file' do
        expect { request.call }.to change(CodeOcean::File, :count)
      end

      expect_json
      expect_status(201)
    end

    context 'with an invalid file' do
      before(:each) { post :create, code_ocean_file: {context_id: submission.id, context_type: Submission}, format: :json }

      expect_assigns(file: CodeOcean::File)
      expect_json
      expect_status(422)
    end
  end

  describe 'DELETE #destroy' do
    let(:exercise) { FactoryGirl.create(:fibonacci) }
    let(:request) { proc { delete :destroy, id: exercise.files.first.id } }
    before(:each) { request.call }

    expect_assigns(file: CodeOcean::File)

    it 'destroys the file' do
      FactoryGirl.create(:fibonacci)
      expect { request.call }.to change(CodeOcean::File, :count).by(-1)
    end

    expect_redirect(:exercise)
  end
end
