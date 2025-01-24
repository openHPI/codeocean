# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController do
  render_views

  let(:user) { create(:learner) }
  let(:rfc_with_comment) { create(:rfc_with_comment, user:) }
  let(:comment) { rfc_with_comment.comments.first }
  let(:updated_comment) { comment.reload }
  let(:perform_request) { proc { put :update, format: :json, params: {id: comment.id, comment: comment_params} } }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'PUT #update' do
    context 'with valid params' do
      before { perform_request.call }

      let(:comment_params) { {text: 'test100'} }

      it 'saves the permitted changes' do
        expect(updated_comment.text).to eq('test100')
      end

      expect_http_status(:ok)
    end

    context 'with additional params' do
      let(:file) { create(:file) }
      let(:comment_params) { {text: 'test100', row: 5, file_id: file.id} }

      context 'when the request is performed' do
        before do
          allow(ActionController::Parameters).to receive(:action_on_unpermitted_parameters).and_return(:log)
          perform_request.call
        end

        it 'applies the permitted changes' do
          expect(updated_comment.row).not_to eq(5)
          expect(updated_comment.file_id).not_to eq(file.id)
          expect(updated_comment.row).to eq(1)
          expect(updated_comment.file_id).to eq(comment.file_id)
          expect(updated_comment.text).to eq('test100')
        end

        expect_http_status(:ok)
      end
    end
  end
end
