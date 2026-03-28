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
        expect_redirect

        it 'redirects to ActiveStorage blob with correct filename' do
          location = response.headers['Location'] || response.location
          expect(location).to include(file.name_with_extension)
          expect(location).to include('disposition=attachment')
        end
      end
    end
  end

  describe 'POST #create' do
    let(:submission) { create(:submission, contributor:) }

    context 'with a valid file' do
      let(:perform_request) { proc { post :create, params: {code_ocean_file: build(:file, context: submission).attributes.slice('name', 'file_type_id', 'file_template_id', 'context_id'), format: :json} } }

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
        post :create, params: {code_ocean_file: {context_id: submission.id}, format: :json}
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

  describe 'GET #render_protected_upload' do
    let(:exercise) { create(:audio_video) }
    let(:submission) { create(:submission, exercise:, contributor: create(:external_user)) }
    let(:file) { exercise.files.detect {|f| f.file_type.file_extension == '.mp4' } }
    let(:token) { Rack::Utils.parse_nested_query(URI.parse(signed_url).query)['token'] }

    context 'with a valid signed URL and matching filename' do
      let(:signed_url) { AuthenticatedUrlHelper.sign(render_protected_upload_url(id: file, filename: file.filepath), file) }

      before do
        get :render_protected_upload, params: {id: file.id, filename: file.filepath, token:}
      end

      expect_assigns(file: :file)
      expect_redirect

      it 'redirects to ActiveStorage blob with inline disposition' do
        location = response.headers['Location'] || response.location
        expect(location).to include('disposition=inline')
        expect(location).to include(file.attachment.filename.to_s)
      end
    end

    context 'with a mismatching filename' do
      let(:signed_url) { AuthenticatedUrlHelper.sign(render_protected_upload_url(id: file, filename: file.filepath), file) }

      it 'returns unauthorized' do
        get :render_protected_upload, params: {id: file.id, filename: 'wrong/name.mp4', token:}
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
