# frozen_string_literal: true

require 'rails_helper'

describe FileTypesController do
  render_views

  let(:file_type) { create(:dot_rb) }
  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid file type' do
      let(:perform_request) { proc { post :create, params: {file_type: attributes_for(:dot_rb)} } }

      before { perform_request.call }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)

      it 'creates the file type' do
        expect { perform_request.call }.to change(FileType, :count).by(1)
      end

      expect_redirect(FileType.last)
    end

    context 'with an invalid file type' do
      before { post :create, params: {file_type: {}} }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)
      expect_http_status(:ok)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: file_type.id} }

    expect_assigns(file_type: FileType)

    it 'destroys the file type' do
      file_type = create(:dot_rb)
      expect { delete :destroy, params: {id: file_type.id} }.to change(FileType, :count).by(-1)
    end

    expect_redirect(:file_types)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: file_type.id} }

    expect_assigns(editor_modes: Array)
    expect_assigns(file_type: FileType)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before do
      create_pair(:dot_rb)
      get :index
    end

    expect_assigns(file_types: FileType.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    before { get :new }

    expect_assigns(editor_modes: Array)
    expect_assigns(file_type: FileType)
    expect_http_status(:ok)
    expect_template(:new)
  end

  describe 'GET #show' do
    before { get :show, params: {id: file_type.id} }

    expect_assigns(file_type: :file_type)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid file type' do
      before { put :update, params: {file_type: attributes_for(:dot_rb), id: file_type.id} }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)
      expect_redirect(:file_type)
    end

    context 'with an invalid file type' do
      before { put :update, params: {file_type: {name: ''}, id: file_type.id} }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)
      expect_http_status(:ok)
      expect_template(:edit)
    end
  end
end
