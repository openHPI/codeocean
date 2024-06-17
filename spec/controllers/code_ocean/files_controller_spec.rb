# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CodeOcean::FilesController do
  render_views

  let(:contributor) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(contributor) }

  describe 'GET #show_protected_upload' do
    context 'with a valid filename' do
      let(:submission) { create(:submission, exercise: create(:audio_video)) }

      before { get :show_protected_upload, params: {filename: file.name_with_extension, id: file.id} }

      context 'with a binary file' do
        let(:file) { submission.collect_files.detect {|file| file.file_type.file_extension == '.mp4' } }

        expect_assigns(file: :file)
        expect_content_type('application/octet-stream')
        expect_http_status(:ok)

        it 'sets the correct filename' do
          expect(response.headers['Content-Disposition']).to include("attachment; filename=\"#{file.name_with_extension}\"")
        end
      end
    end
  end

  describe 'POST #create' do
    let(:submission) { create(:submission, contributor:) }

    context 'with a valid file' do
      let(:perform_request) { proc { post :create, params: {code_ocean_file: build(:file, context: submission).attributes, format: :json} } }

      before do
        submission.exercise.update(allow_file_creation: true)
        perform_request.call
      end

      expect_assigns(file: CodeOcean::File)

      it 'creates the file' do
        expect { perform_request.call }.to change(CodeOcean::File, :count)
      end

      expect_json
      expect_http_status(:created)
    end

    context 'with an invalid file' do
      before do
        submission.exercise.update(allow_file_creation: true)
        post :create, params: {code_ocean_file: {context_id: submission.id, context_type: Submission}, format: :json}
      end

      expect_assigns(file: CodeOcean::File)
      expect_json
      expect_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE #destroy' do
    let!(:exercise) { create(:fibonacci) }
    let(:perform_request) { proc { delete :destroy, params: {id: exercise.files.reject(&:main_file?).first.id} } }

    context 'with request performed' do
      before { perform_request.call }

      expect_assigns(file: CodeOcean::File)

      it 'redirects to exercise path' do
        expect(controller).to redirect_to(exercise)
      end
    end

    it 'destroys the file' do
      expect { perform_request.call }.to change(CodeOcean::File, :count).by(-1)
    end
  end
end
