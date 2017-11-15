require 'rails_helper'

describe FileTypesController do
  let(:file_type) { FactoryBot.create(:dot_rb) }
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid file type' do
      let(:request) { proc { post :create, file_type: FactoryBot.attributes_for(:dot_rb) } }
      before(:each) { request.call }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)

      it 'creates the file type' do
        expect { request.call }.to change(FileType, :count).by(1)
      end

      expect_redirect(FileType.last)
    end

    context 'with an invalid file type' do
      before(:each) { post :create, file_type: {} }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before(:each) { delete :destroy, id: file_type.id }

    expect_assigns(file_type: FileType)

    it 'destroys the file type' do
      file_type = FactoryBot.create(:dot_rb)
      expect { delete :destroy, id: file_type.id }.to change(FileType, :count).by(-1)
    end

    expect_redirect(:file_types)
  end

  describe 'GET #edit' do
    before(:each) { get :edit, id: file_type.id }

    expect_assigns(editor_modes: Array)
    expect_assigns(file_type: FileType)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before(:all) { FactoryBot.create_pair(:dot_rb) }
    before(:each) { get :index }

    expect_assigns(file_types: FileType.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before(:each) { get :new }

    expect_assigns(editor_modes: Array)
    expect_assigns(file_type: FileType)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    before(:each) { get :show, id: file_type.id }

    expect_assigns(file_type: :file_type)
    expect_status(200)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid file type' do
      before(:each) { put :update, file_type: FactoryBot.attributes_for(:dot_rb), id: file_type.id }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)
      expect_redirect(:file_type)
    end

    context 'with an invalid file type' do
      before(:each) { put :update, file_type: {name: ''}, id: file_type.id }

      expect_assigns(editor_modes: Array)
      expect_assigns(file_type: FileType)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
