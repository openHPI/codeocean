require 'rails_helper'

describe CodeOcean::FilesController do
  let(:user) { FactoryGirl.build(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'DELETE #destroy' do
    let(:exercise) { FactoryGirl.create(:fibonacci) }
    let(:request) { Proc.new { delete :destroy, id: exercise.files.first.id } }
    before(:each) { request.call }

    expect_assigns(file: CodeOcean::File)

    it 'destroys the file' do
      exercise = FactoryGirl.create(:fibonacci)
      expect { request.call }.to change(CodeOcean::File, :count).by(-1)
    end

    expect_redirect
  end
end
